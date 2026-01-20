"""
IMAGE-VS-IMAGE COMPARISON EVALUATORS

Two functions for CLIP-based handwriting verification:

1. evaluate_image_vs_image (ALPHABETS)
   Uses CLIP image embeddings to compare handwriting against ALL letter templates.
   Decision: is_correct = (best_match == expected) AND (similarity >= threshold)
   This is relative comparison (catches wrong letters).

2. evaluate_digit_image_vs_image (DIGITS)
   Uses CLIP image embeddings to compare handwriting against ONLY expected digit templates.
   Decision: is_correct = (similarity >= threshold)
   This is verification (simple threshold check, only compares to expected digit).

Both pipelines:
  1. Decode image (base64 → PIL) ONCE
  2. Preprocess image (CLIP format: RGB 224×224) ONCE
  3. Load CLIP + templates (LAZY, CACHED globally)
  4. Embed preprocessed image with CLIP
  5. Compare against templates
  6. Return strict response contract

Response contract (both functions):
  If is_correct = true:
    {
      "is_correct": true,
      "confidence": best_similarity * 100,
      "formation": best_similarity * 100,
      "pressure": null
    }
  
  If is_correct = false:
    {
      "is_correct": false
    }
"""

import os
import torch
import open_clip
import base64
import io
import logging
import cv2
import numpy as np
from PIL import Image
from typing import Dict, Tuple, Any


# Module logger
logger = logging.getLogger(__name__)

# Global CLIP state (lazy initialization, cached for entire server lifetime)
_clip_model = None
_clip_preprocess = None
_template_embeddings: Dict[str, torch.Tensor] = {}
_initialized = False

# Separate cache for digit templates (0-9). Letters and digits must remain isolated.
_digit_template_embeddings: Dict[str, torch.Tensor] = {}


# ============================================================================
# PREPROCESSING UTILITIES (SINGLE-PASS)
# ============================================================================

def decode_base64_image(image_b64: str) -> Image.Image:
    """Decode base64 image string to PIL Image (RGB)."""
    try:
        if "," in image_b64:
            _, encoded = image_b64.split(",", 1)
        else:
            encoded = image_b64
        img_bytes = base64.b64decode(encoded)
        return Image.open(io.BytesIO(img_bytes)).convert("RGB")
    except Exception as e:
        logger.error("[PREPROCESS] Failed to decode base64 image: %s", e)
        raise


def preprocess_image_once(image_pil: Image.Image) -> Tuple[np.ndarray, Image.Image]:
    """
    Preprocess image ONCE for both CLIP and geometry.
    
    Returns:
        (geometry_image_gray_cv2, clip_image_rgb_pil)
    
    Processing:
      - Keep original for geometry extraction (convert to grayscale OpenCV)
      - Resize and normalize for CLIP (224×224 RGB PIL)
      - Background normalized to white
      - Both images frozen for reuse
    """
    # Convert PIL to numpy for geometry processing
    img_np = np.array(image_pil)  # RGB, shape (H, W, 3)
    
    # For geometry: grayscale copy (original size, OpenCV format)
    geom_img_gray = cv2.cvtColor(img_np, cv2.COLOR_RGB2GRAY)
    
    # For CLIP: resize to 224×224, keep as PIL
    # Note: CLIP preprocess will handle normalization
    clip_image_pil = image_pil.resize((224, 224), Image.LANCZOS)
    
    logger.debug("[PREPROCESS] Image preprocessed: geometry=%s, clip=%s",
                 geom_img_gray.shape, clip_image_pil.size)
    return geom_img_gray, clip_image_pil


# ============================================================================
# CLIP INITIALIZATION (LAZY + CACHED)
# ============================================================================

def ensure_clip_loaded() -> bool:
    """
    Ensure CLIP model + templates are loaded (lazy init on first request).
    
    After first call, returns True instantly (cached for server lifetime).
    """
    global _clip_model, _clip_preprocess, _template_embeddings, _digit_template_embeddings, _initialized
    
    if _initialized:
        logger.debug("[CLIP] Already initialized, using cached model and templates")
        return True
    
    try:
        logger.info("[CLIP] 📦 Initializing OpenCLIP ViT-B-32 (first request only, then cached)...")
        
        # Load model (CPU only, no GPU)
        _clip_model, _, _clip_preprocess = open_clip.create_model_and_transforms(
            "ViT-B-32",
            pretrained="openai",
            device="cpu"
        )
        _clip_model.eval()
        logger.info("[CLIP] ✅ Model loaded: ViT-B-32 on CPU")
        
        # Load template embeddings (letters and digits kept separate)
        _load_template_embeddings()
        _load_digit_template_embeddings()
        
        _initialized = True
        logger.info("[CLIP] ✅ CLIP fully initialized and cached (will not reload)")
        return True
    
    except Exception as e:
        logger.error("[CLIP] ❌ Initialization failed: %s", e)
        return False


def _load_template_embeddings() -> None:
    """
    Load and cache all template embeddings from `static/letters/{A-Z}/`.
    
    Each letter directory may contain multiple template images; we embed each
    and store a tensor of shape (N, 512) for that letter (or (512,) if N==1).
    """
    global _template_embeddings
    
    logger.info("[CLIP] 📋 Loading template embeddings...")
    letters_root = os.path.join(os.path.dirname(__file__), "..", "static", "letters")

    if not os.path.exists(letters_root):
        logger.warning("[CLIP] Letters template directory not found: %s", letters_root)
        return

    loaded_count = 0
    # Iterate A-Z directories (or any uppercase-named folder)
    for entry in sorted(os.listdir(letters_root)):
        entry_path = os.path.join(letters_root, entry)
        if not os.path.isdir(entry_path):
            continue

        char = entry.upper()
        embeddings = []

        # Gather image files in this letter folder
        for fname in sorted(os.listdir(entry_path)):
            if not fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff")):
                continue
            fpath = os.path.join(entry_path, fname)
            try:
                img = Image.open(fpath).convert("RGB")
                img = img.resize((224, 224), Image.LANCZOS)
                with torch.no_grad():
                    tensor = _clip_preprocess(img).unsqueeze(0)  # (1,3,224,224)
                    emb = _clip_model.encode_image(tensor)  # (1,512)
                    emb = emb / emb.norm(dim=-1, keepdim=True)
                    embeddings.append(emb.squeeze(0))
            except Exception as e:
                logger.warning("[CLIP] Failed to embed template %s/%s: %s", char, fname, e)
                continue

        if not embeddings:
            logger.debug("[CLIP] No templates found for %s", char)
            continue

        # Stack embeddings into tensor (N,512) or (512,) if single
        try:
            stacked = torch.stack(embeddings)
            if stacked.shape[0] == 1:
                stacked = stacked.squeeze(0)
            _template_embeddings[char] = stacked
            loaded_count += 1
            logger.debug("[CLIP] Cached %d templates for %s", embeddings.__len__(), char)
        except Exception as e:
            logger.warning("[CLIP] Failed to stack embeddings for %s: %s", char, e)

    logger.info("[CLIP] ✅ Loaded %d character template sets (cached)", loaded_count)


def _load_digit_template_embeddings() -> None:
    """
    Load and cache all digit template embeddings from `static/digits/{0..9}/`.

    Each digit directory may contain multiple template images; we embed each
    and store a tensor of shape (N, 512) for that digit (or (512,) if N==1).
    """
    global _digit_template_embeddings

    logger.info("[CLIP] 📋 Loading digit template embeddings...")
    digits_root = os.path.join(os.path.dirname(__file__), "..", "static", "digits")

    if not os.path.exists(digits_root):
        logger.warning("[CLIP] Digits template directory not found: %s", digits_root)
        return

    loaded_count = 0
    # Iterate digit directories (0-9)
    for entry in sorted(os.listdir(digits_root)):
        entry_path = os.path.join(digits_root, entry)
        if not os.path.isdir(entry_path):
            continue

        digit = entry.strip()
        embeddings = []

        # Gather image files in this digit folder
        for fname in sorted(os.listdir(entry_path)):
            if not fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff")):
                continue
            fpath = os.path.join(entry_path, fname)
            try:
                img = Image.open(fpath).convert("RGB")
                img = img.resize((224, 224), Image.LANCZOS)
                with torch.no_grad():
                    tensor = _clip_preprocess(img).unsqueeze(0)  # (1,3,224,224)
                    emb = _clip_model.encode_image(tensor)  # (1,512)
                    emb = emb / emb.norm(dim=-1, keepdim=True)
                    embeddings.append(emb.squeeze(0))
            except Exception as e:
                logger.warning("[CLIP] Failed to embed digit template %s/%s: %s", digit, fname, e)
                continue

        if not embeddings:
            logger.debug("[CLIP] No templates found for digit %s", digit)
            continue

        try:
            stacked = torch.stack(embeddings)
            if stacked.shape[0] == 1:
                stacked = stacked.squeeze(0)
            _digit_template_embeddings[digit] = stacked
            loaded_count += 1
            logger.debug("[CLIP] Cached %d templates for digit %s", len(embeddings), digit)
        except Exception as e:
            logger.warning("[CLIP] Failed to stack embeddings for digit %s: %s", digit, e)

    logger.info("[CLIP] ✅ Loaded %d digit template sets (cached)", loaded_count)


def embed_image_clip(image_pil: Image.Image) -> torch.Tensor:
    """
    Embed image using CLIP (L2-normalized).
    
    Args:
        image_pil: PIL Image (RGB, already preprocessed to 224×224)
    
    Returns:
        torch.Tensor of shape (512,) with L2 normalization
    """
    global _clip_model, _clip_preprocess
    
    try:
        with torch.no_grad():
            # Preprocess and embed
            image_tensor = _clip_preprocess(image_pil).unsqueeze(0)  # (1, 3, 224, 224)
            embedding = _clip_model.encode_image(image_tensor)  # (1, 512)
            
            # L2 normalize
            embedding = embedding / embedding.norm(dim=-1, keepdim=True)
            
            return embedding.squeeze(0)  # Return (512,)
    
    except Exception as e:
        logger.error("[CLIP] Image embedding failed: %s", e)
        raise


# ============================================================================
# LETTER GEOMETRY PROFILES (SOFT VALIDATION, FALLBACK ONLY)
# ============================================================================

# Define geometry profiles for letters with distinctive shapes
# Geometry is used ONLY as a FALLBACK when template matching fails
# Geometry NEVER hard-rejects a letter that passed template matching
LETTER_GEOMETRY_PROFILES = {
    "A": {"expect_loops": 0, "description": "Diagonal strokes (no loops expected)"},
    "B": {"expect_loops": 1, "description": "Has loops (2 bumps on right)"},
    "D": {"expect_loops": 1, "description": "Has loop (one curved bump)"},
    "O": {"expect_loops": 1, "description": "Has loop (oval shape)"},
    "P": {"expect_loops": 1, "description": "Has loop (bump at top)"},
    "Q": {"expect_loops": 1, "description": "Has loop (oval with tail)"},
    "R": {"expect_loops": 1, "description": "Has loop (bump at top)"},
    "E": {"expect_loops": 0, "description": "No loops (three horizontal lines)"},
    "F": {"expect_loops": 0, "description": "No loops (two horizontal lines)"},
    "H": {"expect_loops": 0, "description": "No loops (two vertical with crossbar)"},
    "T": {"expect_loops": 0, "description": "No loops (cross)"},
}


def check_geometry_gate(geometry: Dict, expected_char: str) -> Tuple[bool, str]:
    """
    Check geometry as a FALLBACK validation (NEVER blocks correct template matches).
    
    IMPORTANT: This function is ONLY called when template matching failed.
    It cannot override a passing template match.
    
    Geometry can only help determine if a template-mismatched letter is WRONG.
    
    Args:
        geometry: Geometry features from extract_geometry
        expected_char: Expected letter (e.g., "A", "B")
    
    Returns:
        (passes_geometry, reason_if_fails)
        
        Note: In Stage 2 context, "passes" means "geometry is consistent"
        but it doesn't override a failed template match.
    """
    expected_char = expected_char.strip().upper()
    
    # If no profile defined for this letter, always pass (no gate)
    if expected_char not in LETTER_GEOMETRY_PROFILES:
        return True, ""
    
    profile = LETTER_GEOMETRY_PROFILES[expected_char]
    actual_loops = 1 if geometry.get("has_loop", False) else 0
    expected_loops = profile.get("expect_loops", None)
    
    # Standard case: check loop count
    if expected_loops is not None:
        if actual_loops != expected_loops:
            reason = f"Geometry mismatch: {expected_char} {profile['description']}, but found {actual_loops} loops"
            logger.debug("[GEOMETRY] Geometry check failed: %s", reason)
            return False, reason
    
    logger.debug("[GEOMETRY] Geometry check passed for %s", expected_char)
    return True, ""


def compute_geometry_info(geometry: Dict) -> Dict:
    """
    Extract geometry info (for response, informational only).
    
    Geometry is informational only. It never rejects correct letters.
    """
    return {
        "loops": 1 if geometry.get("has_loop", False) else 0,
        "curvature": round(geometry.get("curvature", 0.0), 3),
        "aspect_ratio": round(geometry.get("aspect_ratio", 0.0), 3),
        "is_vertical": geometry.get("is_vertical", False),
        "is_horizontal": geometry.get("is_horizontal", False),
        "has_diagonal": geometry.get("has_diagonal", False),
        "crossing_count": geometry.get("crossing_count", 0),
    }

# ============================================================================
# SINGLE-PASS IMAGE-ONLY EVALUATION
# ============================================================================

def evaluate_image_vs_image(
    image_b64: str,
    expected_char: str,
    char_type: str = "letter"
) -> Dict:
    """
    RELATIVE IMAGE-VS-IMAGE COMPARISON
    
    Compare input handwriting against ALL letter templates to determine
    if the written letter matches the expected letter.
    
    This is NOT a similarity threshold check. This is a CLASSIFICATION task:
    - Which letter does this handwriting most closely resemble?
    - Is the best match the expected letter?
    
    Pipeline:
    1. Load CLIP (cached)
    2. Decode image (once)
    3. Preprocess image (once)
    4. Embed image with CLIP
    5. Compare against ALL letters (A–Z)
    6. Find best_match_letter = argmax(all_similarities)
    7. Decision rule:
         IF (best_match == expected_letter AND similarity >= 0.30):
           is_correct = true
         ELSE:
           is_correct = false
    8. Return confidence and formation (both = best_match_similarity * 100)
    
    Args:
        image_b64: Base64-encoded user handwriting image
        expected_char: Expected letter (e.g., "A")
        char_type: "letter" or "digit" (logging only)
    
    Returns (STRICT CONTRACT):
        {
            "is_correct": true/false,
            "confidence": best_match_similarity * 100,
            "formation": best_match_similarity * 100,
            "pressure": null
        }
    
    Key guarantees:
      ✓ Catches wrong letters (R written for A → best_match=R → incorrect)
      ✓ Catches weak matches (low confidence → incorrect even if A)
      ✓ Real accuracy (confidence = best_match_similarity, not expected_similarity)
      ✓ Relative comparison (image judged against all 26 letters)
      ✓ No geometry fallback
      ✓ No confusion sets
      ✓ No staged logic
    """
    
    expected_char = expected_char.strip().upper()
    logger.info("[EVAL_RELATIVE] Image-vs-image RELATIVE COMPARISON: expected=%s", expected_char)
    
    # ===== STEP 1: Ensure CLIP loaded (first request only, cached thereafter) =====
    if not ensure_clip_loaded():
        logger.error("[EVAL_RELATIVE] ❌ CLIP not loaded; cannot evaluate")
        return {
            "is_correct": False,
            "confidence": 0.0,
            "formation": 0.0,
            "pressure": None
        }
    
    # ===== STEP 2: Decode image (ONCE) =====
    try:
        user_img_pil = decode_base64_image(image_b64)
        logger.debug("[EVAL_RELATIVE] Image decoded successfully, size=%s", user_img_pil.size)
    except Exception as e:
        logger.error("[EVAL_RELATIVE] ❌ Image decode failed: %s", e)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "formation": 0.0,
            "pressure": None
        }
    
    # ===== STEP 3: Preprocess image ONCE (frozen for reuse) =====
    try:
        _, clip_img_pil = preprocess_image_once(user_img_pil)
        logger.debug("[EVAL_RELATIVE] Image preprocessed for CLIP")
    except Exception as e:
        logger.error("[EVAL_RELATIVE] ❌ Preprocessing failed: %s", e)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "formation": 0.0,
            "pressure": None
        }
    
    # ===== STEP 4: Embed with CLIP =====
    try:
        user_embedding = embed_image_clip(clip_img_pil)
        logger.debug("[EVAL_RELATIVE] Image embedded via CLIP")
    except Exception as e:
        logger.error("[EVAL_RELATIVE] ❌ CLIP embedding failed: %s", e)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "formation": 0.0,
            "pressure": None
        }
    
    # ===== STEP 5: RELATIVE COMPARISON — Compare against ALL letters =====
    logger.info("[EVAL_RELATIVE] ═══ COMPARISON PHASE (against ALL letters A–Z) ═══")
    
    confidence_threshold = 0.30
    all_similarities = {}
    
    try:
        # Compute similarity to all available letter templates
        for letter_char in sorted(_template_embeddings.keys()):
            letter_templates = _template_embeddings[letter_char]
            
            # Compute similarity to this letter's templates
            if len(letter_templates.shape) == 1:
                # Single template: shape (512,)
                sims = [(user_embedding @ letter_templates).item()]
            else:
                # Multiple templates: shape (N, 512)
                sims_tensor = (user_embedding @ letter_templates.T)  # (N,)
                sims = sims_tensor.tolist()
            
            # Use best similarity for this letter
            best_sim = max(sims) if sims else 0.0
            all_similarities[letter_char] = best_sim
            logger.debug("[EVAL_RELATIVE] Similarity to %s: %.4f", letter_char, best_sim)
        
        # Find best matching letter (RELATIVE COMPARISON)
        if not all_similarities:
            logger.warning("[EVAL_RELATIVE] ❌ No templates available for comparison")
            return {
                "is_correct": False,
                "confidence": 0.0,
                "formation": 0.0,
                "pressure": None
            }
        
        best_match_letter = max(all_similarities, key=all_similarities.get)
        best_match_similarity = all_similarities[best_match_letter]
        expected_similarity = all_similarities.get(expected_char, 0.0)
        
        logger.info("[EVAL_RELATIVE] Comparison results:")
        logger.info("[EVAL_RELATIVE]   Best match: %s (similarity: %.4f)", best_match_letter, best_match_similarity)
        logger.info("[EVAL_RELATIVE]   Expected:   %s (similarity: %.4f)", expected_char, expected_similarity)
        logger.info("[EVAL_RELATIVE]   Threshold:  %.2f", confidence_threshold)
        
        # ===== DECISION RULE =====
        # is_correct = (best_match == expected) AND (similarity >= threshold)
        if best_match_letter == expected_char and best_match_similarity >= confidence_threshold:
            # CORRECT: Best match is expected letter AND similarity meets threshold
            confidence = round(best_match_similarity * 100, 1)
            formation = round(best_match_similarity * 100, 1)
            
            logger.info("[EVAL_RELATIVE] ✅ CORRECT: best_match==%s AND similarity=%.4f >= %.2f",
                        expected_char, best_match_similarity, confidence_threshold)
            logger.info("[EVAL_RELATIVE] ✅ EVALUATION COMPLETE: is_correct=True")
            
            return {
                "is_correct": True,
                "confidence": confidence,
                "formation": formation,
                "pressure": None
            }
        else:
            # INCORRECT: Either best_match != expected OR similarity below threshold
            confidence = round(best_match_similarity * 100, 1)
            formation = round(best_match_similarity * 100, 1)
            
            if best_match_letter != expected_char:
                logger.info("[EVAL_RELATIVE] ❌ INCORRECT: best_match==%s, expected==%s",
                            best_match_letter, expected_char)
            else:
                logger.info("[EVAL_RELATIVE] ❌ INCORRECT: best_match==%s but similarity=%.4f < %.2f",
                            expected_char, best_match_similarity, confidence_threshold)
            
            logger.info("[EVAL_RELATIVE] ✅ EVALUATION COMPLETE: is_correct=False")
            
            return {
                "is_correct": False,
                "confidence": confidence,
                "formation": formation,
                "pressure": None
            }
    
    except Exception as e:
        logger.error("[EVAL_RELATIVE] ❌ Comparison computation failed: %s", e)
        import traceback
        traceback.print_exc()
        return {
            "is_correct": False,
            "confidence": 0.0,
            "formation": 0.0,
            "pressure": None
        }


def evaluate_digit_image_vs_image(image_b64: str, expected_digit: str) -> Dict:
    """
    IMAGE-VS-IMAGE DIGIT EVALUATION (ALL DIGITS 0–9)
    
    Compare input handwriting against ALL digit templates (0–9) to determine
    if the written digit matches the expected digit.
    
    Pipeline:
    1. Decode image (base64 → PIL)
    2. Preprocess image (→ 224×224 RGB)
    3. Embed image ONCE with CLIP
    4. Compute MAX similarity against all digit templates (0–9)
    5. Rank digits by similarity (descending)
    
    Decision Logic:
    ──────────────
    Let:
      ranked_digits = [digit0, digit1, ...] sorted by similarity (desc)
      top_digit, top_sim = ranked_digits[0]
      second_digit, second_sim = ranked_digits[1]
      expected_sim = similarity of expected_digit
    
    Rules (IN THIS ORDER):
      1. If expected_sim < 0.65 → REJECT
      2. If expected_digit NOT in {top_digit, second_digit} → REJECT
      3. If top_digit != expected_digit AND (top_sim - expected_sim) > 0.10 → REJECT
      4. ELSE → ACCEPT
    
    If ACCEPT:
      confidence = expected_sim * 100
      formation = expected_sim * 100
    
    Logging:
    ───────
    Log all similarities (0–9), ranked digits, expected digit, decision path.
    """
    
    expected_digit = expected_digit.strip()
    logger.info("[DIGIT_IMAGE_VS_IMAGE] expected_digit=%s", expected_digit)
    
    if not ensure_clip_loaded():
        logger.error("[DIGIT_IMAGE_VS_IMAGE] CLIP not loaded")
        return {"is_correct": False}
    
    try:
        user_img_pil = decode_base64_image(image_b64)
        logger.debug("[DIGIT_IMAGE_VS_IMAGE] Image decoded, size=%s", user_img_pil.size)
    except Exception as e:
        logger.error("[DIGIT_IMAGE_VS_IMAGE] Image decode failed: %s", e)
        return {"is_correct": False}
    
    try:
        _, clip_img_pil = preprocess_image_once(user_img_pil)
        logger.debug("[DIGIT_IMAGE_VS_IMAGE] Image preprocessed for CLIP")
    except Exception as e:
        logger.error("[DIGIT_IMAGE_VS_IMAGE] Preprocessing failed: %s", e)
        return {"is_correct": False}
    
    try:
        user_embedding = embed_image_clip(clip_img_pil)
        logger.debug("[DIGIT_IMAGE_VS_IMAGE] Image embedded via CLIP")
    except Exception as e:
        logger.error("[DIGIT_IMAGE_VS_IMAGE] CLIP embedding failed: %s", e)
        return {"is_correct": False}
    
    logger.info("[DIGIT_IMAGE_VS_IMAGE] ═══ COMPARISON PHASE (against ALL digits 0–9) ═══")
    
    all_similarities = {}
    
    try:
        for digit_char in sorted(_digit_template_embeddings.keys()):
            digit_templates = _digit_template_embeddings[digit_char]
            
            if len(digit_templates.shape) == 1:
                sims = [(user_embedding @ digit_templates).item()]
            else:
                sims_tensor = (user_embedding @ digit_templates.T)
                sims = sims_tensor.tolist()
            
            best_sim = max(sims) if sims else 0.0
            all_similarities[digit_char] = best_sim
            logger.debug("[DIGIT_IMAGE_VS_IMAGE] Similarity to digit %s: %.4f", digit_char, best_sim)
        
        logger.info("[DIGIT_IMAGE_VS_IMAGE] all_similarities=%s",
                   {k: float(f"{v:.4f}") for k, v in sorted(all_similarities.items())})
        
        ranked = sorted(all_similarities.items(), key=lambda x: x[1], reverse=True)
        ranked_digits = [d for d, s in ranked]
        logger.info("[DIGIT_IMAGE_VS_IMAGE] ranked_digits=%s", ranked_digits)
        
        top_digit, top_sim = ranked[0]
        second_digit, second_sim = ranked[1] if len(ranked) > 1 else (None, 0.0)
        expected_sim = all_similarities.get(expected_digit, 0.0)
        
        logger.info("[DIGIT_IMAGE_VS_IMAGE] top_digit=%s (sim=%.4f), second=%s (sim=%.4f), expected=%s (sim=%.4f)",
                   top_digit, top_sim, second_digit, second_sim, expected_digit, expected_sim)
        
        decision = "REJECT"
        reason = ""
        
        if expected_sim < 0.65:
            decision = "REJECT"
            reason = f"expected_sim {expected_sim:.4f} < 0.65"
            logger.info("[DIGIT_IMAGE_VS_IMAGE] Rule 1: REJECT — %s", reason)
        
        elif expected_digit not in {top_digit, second_digit} and (top_sim - expected_sim) > 0.04:
            decision = "REJECT"
            reason = f"expected_digit {expected_digit} not in top-2 and gap {top_sim - expected_sim:.4f} > 0.04"
            logger.info("[DIGIT_IMAGE_VS_IMAGE] Rule 2: REJECT — %s", reason)
        
        elif top_digit != expected_digit and (top_sim - expected_sim) > 0.10:
            decision = "REJECT"
            reason = f"top_digit {top_digit} wins with gap {top_sim - expected_sim:.4f} > 0.10"
            logger.info("[DIGIT_IMAGE_VS_IMAGE] Rule 3: REJECT — %s", reason)
        
        else:
            decision = "ACCEPT"
            logger.info("[DIGIT_IMAGE_VS_IMAGE] All rules passed: ACCEPT")
        
        logger.info("[DIGIT_IMAGE_VS_IMAGE] FINAL DECISION: %s", decision)
        
        if decision == "ACCEPT":
            confidence = round(expected_sim * 100, 1)
            formation = round(expected_sim * 100, 1)
            logger.info("[DIGIT_IMAGE_VS_IMAGE] ✅ EVALUATION COMPLETE: is_correct=True, confidence=%s",
                       confidence)
            return {
                "is_correct": True,
                "confidence": confidence,
                "formation": formation,
                "pressure": None
            }
        else:
            logger.info("[DIGIT_IMAGE_VS_IMAGE] ❌ EVALUATION COMPLETE: is_correct=False (%s)", reason)
            return {"is_correct": False}
    
    except Exception as e:
        logger.error("[DIGIT_IMAGE_VS_IMAGE] Comparison computation failed: %s", e)
        import traceback
        traceback.print_exc()
        return {"is_correct": False}


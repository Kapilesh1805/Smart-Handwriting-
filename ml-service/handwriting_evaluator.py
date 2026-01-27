"""
CLIP-based handwriting evaluation for ML service.
Simplified version for containerized deployment.
"""

import os
import torch
import open_clip
import base64
import io
import logging
from PIL import Image
from typing import Dict, Tuple, Optional
import numpy as np
import threading
import time

# Module logger
logger = logging.getLogger(__name__)

# ============================================================================
# CONFIGURATION FLAGS
# ============================================================================
USE_CLIP = True
CLIP_OPTIONAL = False  # CLIP is now required
CLIP_TIMEOUT_MS = 300

# Global CLIP state - SINGLETON INITIALIZATION
_clip_model = None
_clip_preprocess = None
_quality_text_embeddings = None  # Cached quality assessment embeddings

# Global template embeddings
_template_embeddings: Dict[str, torch.Tensor] = {}
_digit_template_embeddings: Dict[str, torch.Tensor] = {}
_initialized = False
_init_lock = None

def ensure_clip_loaded() -> bool:
    """Ensure CLIP model and templates are loaded - THREAD-SAFE SINGLETON."""
    global _clip_model, _clip_preprocess, _initialized, _init_lock

    if _initialized:
        return True

    # Import here to avoid circular imports
    import threading

    if _init_lock is None:
        _init_lock = threading.Lock()

    with _init_lock:
        if _initialized:
            return True

        try:
            logger.info("[CLIP] Loading CLIP ViT-B-32 model...")

            # Load CLIP model
            _clip_model, _, _clip_preprocess = open_clip.create_model_and_transforms(
                'ViT-B-32', pretrained='openai'
            )
            _clip_model.eval()

            # Load templates
            _load_template_embeddings()
            _load_digit_template_embeddings()

            # Cache quality assessment embeddings
            _cache_quality_embeddings()

            _initialized = True
            logger.info("[CLIP] CLIP initialized successfully")
            return True

        except Exception as e:
            logger.error("[CLIP] Failed to initialize CLIP: %s", e)
            return False


def _load_template_embeddings() -> None:
    """Load letter template embeddings."""
    global _template_embeddings

    logger.info("[CLIP] Loading letter template embeddings...")
    letters_root = os.path.join(os.path.dirname(__file__), "reference_shapes", "letters")

    if not os.path.exists(letters_root):
        logger.warning("[CLIP] Letters template directory not found: %s", letters_root)
        return

    loaded_count = 0
    for entry in sorted(os.listdir(letters_root)):
        entry_path = os.path.join(letters_root, entry)
        if not os.path.isdir(entry_path):
            continue

        char = entry.upper()
        embeddings = []

        for fname in sorted(os.listdir(entry_path)):
            if not fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff")):
                continue
            fpath = os.path.join(entry_path, fname)
            try:
                img = Image.open(fpath).convert("RGB")
                img = img.resize((224, 224), Image.LANCZOS)
                with torch.no_grad():
                    tensor = _clip_preprocess(img).unsqueeze(0)
                    emb = _clip_model.encode_image(tensor)
                    emb = emb / emb.norm(dim=-1, keepdim=True)
                    embeddings.append(emb.squeeze(0))
            except Exception as e:
                logger.warning("[CLIP] Failed to embed template %s/%s: %s", char, fname, e)
                continue

        if not embeddings:
            logger.debug("[CLIP] No templates found for %s", char)
            continue

        try:
            stacked = torch.stack(embeddings)
            _template_embeddings[char] = stacked
            loaded_count += 1
            logger.debug("[CLIP] Loaded %d templates for %s", len(embeddings), char)
        except Exception as e:
            logger.error("[CLIP] Failed to stack embeddings for %s: %s", char, e)

    logger.info("[CLIP] Loaded templates for %d letters", loaded_count)


def _load_digit_template_embeddings() -> None:
    """Load digit template embeddings."""
    global _digit_template_embeddings

    logger.info("[CLIP] Loading digit template embeddings...")
    digits_root = os.path.join(os.path.dirname(__file__), "reference_shapes", "digits")

    if not os.path.exists(digits_root):
        logger.warning("[CLIP] Digits template directory not found: %s", digits_root)
        return

    loaded_count = 0
    for entry in sorted(os.listdir(digits_root)):
        entry_path = os.path.join(digits_root, entry)
        if not os.path.isdir(entry_path):
            continue

        char = entry.upper()
        embeddings = []

        for fname in sorted(os.listdir(entry_path)):
            if not fname.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff")):
                continue
            fpath = os.path.join(entry_path, fname)
            try:
                img = Image.open(fpath).convert("RGB")
                img = img.resize((224, 224), Image.LANCZOS)
                with torch.no_grad():
                    tensor = _clip_preprocess(img).unsqueeze(0)
                    emb = _clip_model.encode_image(tensor)
                    emb = emb / emb.norm(dim=-1, keepdim=True)
                    embeddings.append(emb.squeeze(0))
            except Exception as e:
                logger.warning("[CLIP] Failed to embed digit template %s/%s: %s", char, fname, e)
                continue

        if not embeddings:
            logger.debug("[CLIP] No templates found for digit %s", char)
            continue

        try:
            stacked = torch.stack(embeddings)
            _digit_template_embeddings[char] = stacked
            loaded_count += 1
            logger.debug("[CLIP] Loaded %d templates for digit %s", len(embeddings), char)
        except Exception as e:
            logger.error("[CLIP] Failed to stack embeddings for digit %s: %s", char, e)

    logger.info("[CLIP] Loaded templates for %d digits", loaded_count)


def _cache_quality_embeddings() -> None:
    """
    Cache CLIP text embeddings for quality assessment prompts at startup.

    This ensures quality evaluation is fast during inference.
    """
    global _quality_text_embeddings

    logger.info("[CLIP] Caching quality assessment embeddings...")

    # Define quality assessment prompts (letter-agnostic for now)
    quality_prompts = [
        # Shape accuracy prompts
        "a perfectly formed letter with correct shape",
        "a letter with accurate curves and lines",
        "a letter with proper geometric proportions",

        # Proportion & alignment prompts
        "a well-proportioned letter with good balance",
        "a letter with correct height and width ratio",
        "a centered and aligned letter",

        # Neatness / stroke smoothness prompts
        "a neat and clean handwritten letter",
        "a letter with smooth, flowing strokes",
        "a carefully written letter without smudges",

        # Negative examples for contrast
        "a messy and sloppy letter",
        "a poorly formed letter with wrong shapes",
        "an uneven and unbalanced letter"
    ]

    try:
        # Tokenize and encode prompts
        text_tokens = open_clip.tokenize(quality_prompts)
        with torch.no_grad():
            embeddings = _clip_model.encode_text(text_tokens)
            embeddings = embeddings / embeddings.norm(dim=-1, keepdim=True)
            _quality_text_embeddings = embeddings

        logger.info("[CLIP] Cached %d quality assessment embeddings", len(quality_prompts))

    except Exception as e:
        logger.error("[CLIP] Failed to cache quality embeddings: %s", e)
        _quality_text_embeddings = None


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


def preprocess_image_once(image_pil: Image.Image) -> Image.Image:
    """Preprocess image for CLIP."""
    return image_pil.resize((224, 224), Image.LANCZOS)


def embed_image_clip(clip_img_pil: Image.Image) -> torch.Tensor:
    """Embed image using CLIP."""
    with torch.no_grad():
        tensor = _clip_preprocess(clip_img_pil).unsqueeze(0)
        embedding = _clip_model.encode_image(tensor)
        embedding = embedding / embedding.norm(dim=-1, keepdim=True)
        return embedding.squeeze(0)


def detect_letter_with_clip(image_pil: Image.Image) -> Tuple[Optional[str], float]:
    """
    Detect the letter in the image using CLIP template matching.
    
    Returns:
        Tuple of (detected_char, confidence) or (None, 0.0) if no good match
    """
    if not ensure_clip_loaded():
        logger.warning("[CLIP_DETECT] CLIP not available")
        return None, 0.0

    try:
        # Preprocess and embed user image
        clip_img = preprocess_image_once(image_pil)
        user_embedding = embed_image_clip(clip_img)

        # Compare against ALL letters
        all_similarities = {}

        for letter_char in sorted(_template_embeddings.keys()):
            letter_templates = _template_embeddings[letter_char]

            if len(letter_templates.shape) == 1:
                sims = [(user_embedding @ letter_templates).item()]
            else:
                sims_tensor = (user_embedding @ letter_templates.T)
                sims = sims_tensor.tolist()

            best_sim = max(sims) if sims else 0.0
            all_similarities[letter_char] = best_sim

        if not all_similarities:
            return None, 0.0

        # Sort by similarity
        ranked = sorted(all_similarities.items(), key=lambda x: x[1], reverse=True)
        best_letter, best_sim = ranked[0]

        # More sophisticated decision: check if expected is in top 3 or close
        # For now, simple threshold - lowered for better lowercase detection
        confidence_threshold = 0.65  # Lower threshold for better detection of lowercase letters

        if best_sim < confidence_threshold:
            logger.info("[CLIP_DETECT] Best match '%s' confidence %.2f too low", best_letter, best_sim)
            return None, 0.0

        logger.info("[CLIP_DETECT] Detected: '%s' with confidence %.2f", best_letter, best_sim)
        return best_letter, best_sim

    except Exception as e:
        logger.error("[CLIP_DETECT] Detection failed: %s", e)
        return None, 0.0


def evaluate_quality_with_clip(image_pil: Image.Image, expected_char: str) -> Tuple[int, str, str]:
    """
    Evaluate handwriting quality using interpretable CLIP-based scoring.

    Assesses three key components:
    1. Shape Accuracy: How well the letter shape matches the expected form
    2. Proportion & Alignment: Balance, centering, and geometric proportions
    3. Neatness: Stroke smoothness and overall cleanliness

    Returns:
        (quality_score_0_100, quality_label, specific_feedback)
    """
    if not ensure_clip_loaded() or _quality_text_embeddings is None:
        logger.error("[QUALITY] CLIP or quality embeddings not available")
        return 50, "Needs Improvement", "Unable to assess quality"

    try:
        # Preprocess and embed user image
        clip_img = preprocess_image_once(image_pil)
        user_embedding = embed_image_clip(clip_img)

        # Compute similarities with cached quality embeddings
        similarities = (user_embedding @ _quality_text_embeddings.T).tolist()

        # Extract component scores (indices based on prompt order)
        # Shape accuracy (indices 0-2)
        shape_scores = similarities[0:3]
        shape_accuracy = sum(shape_scores) / len(shape_scores)

        # Proportion & alignment (indices 3-5)
        proportion_scores = similarities[3:6]
        proportion_alignment = sum(proportion_scores) / len(proportion_scores)

        # Neatness (indices 6-8)
        neatness_scores = similarities[6:9]
        neatness = sum(neatness_scores) / len(neatness_scores)

        # Negative contrast (indices 9-11) - higher similarity to bad examples reduces score
        negative_scores = similarities[9:12]
        negative_penalty = sum(negative_scores) / len(negative_scores)

        # Weighted scoring: emphasize positive aspects, penalize negative
        # Weights: Shape (40%), Proportion (35%), Neatness (25%)
        weighted_score = (
            shape_accuracy * 0.40 +
            proportion_alignment * 0.35 +
            neatness * 0.25
        )

        # Apply negative penalty (reduce score if similar to bad examples)
        adjusted_score = weighted_score - (negative_penalty * 0.20)

        # Convert to 0-100 scale
        quality_score = max(0, min(100, int((adjusted_score + 1) * 50)))

        # Determine label and feedback based on component analysis
        quality_label, feedback = generate_quality_feedback(
            expected_char, quality_score, shape_accuracy, proportion_alignment, neatness
        )

        logger.info("[QUALITY] Score: %d (Shape: %.2f, Prop: %.2f, Neat: %.2f)",
                   quality_score, shape_accuracy, proportion_alignment, neatness)

        return quality_score, quality_label, feedback

    except Exception as e:
        logger.error("[QUALITY] CLIP quality evaluation failed: %s", e)
        return 50, "Needs Improvement", "Unable to assess quality"


def generate_quality_feedback(expected_char: str, overall_score: int,
                            shape_accuracy: float, proportion_alignment: float,
                            neatness: float) -> Tuple[str, str]:
    """
    Generate specific, child-friendly feedback based on quality component analysis.

    Focuses on the weakest component to provide actionable improvement guidance.
    """
    # Determine overall label
    if overall_score >= 80:
        label = "Excellent"
    elif overall_score >= 60:
        label = "Good"
    else:
        label = "Needs Improvement"

    # Find the weakest component for specific feedback
    components = {
        'shape': shape_accuracy,
        'proportion': proportion_alignment,
        'neatness': neatness
    }

    weakest_component = min(components, key=components.get)
    weakest_score = components[weakest_component]

    # Generate specific feedback based on weakest component
    if label == "Excellent":
        feedback = f"Excellent work on your {expected_char}! It looks perfect."
    elif label == "Good":
        if weakest_component == 'shape':
            feedback = f"Good job! Your {expected_char} shape is almost right. Try making the curves smoother."
        elif weakest_component == 'proportion':
            feedback = f"Well done! Your {expected_char} just needs better balance. Make sure it's not too tall or wide."
        else:  # neatness
            feedback = f"Nice work! Your {expected_char} would be even better with cleaner, smoother lines."
    else:  # Needs Improvement
        if weakest_component == 'shape':
            feedback = f"You're getting there! Focus on the correct shape for {expected_char}. Look at how it should curve."
        elif weakest_component == 'proportion':
            feedback = f"Keep trying! Make your {expected_char} more balanced - not too stretched or squished."
        else:  # neatness
            feedback = f"Good effort! Try writing your {expected_char} more slowly for smoother, neater lines."

    return label, feedback


def determine_legibility_status(detected_char: Optional[str], ocr_confidence: float, expected_char: str) -> Tuple[str, str]:
    """
    Determine legibility status using tiered confidence thresholds.

    Returns:
        (legibility_status, confidence_tier)

    Tiers:
        ≥ 0.90 → PASS (Very Clear)
        0.75–0.89 → PASS (Clear Enough)
        0.60–0.74 → WEAK PASS (Accept but suggest retry)
        < 0.60 → FAIL
    """
    if not detected_char or detected_char != expected_char:
        return "FAIL", "no_match"

    if ocr_confidence >= 0.90:
        return "PASS", "very_clear"
    elif ocr_confidence >= 0.75:
        return "PASS", "clear_enough"
    elif ocr_confidence >= 0.60:
        return "WEAK_PASS", "unclear"  # Accept but suggest improvement
    else:
        return "FAIL", "illegible"


def generate_illegible_feedback(detected_char: Optional[str], expected_char: str, confidence_tier: str) -> str:
    """
    Generate specific, encouraging feedback for illegible letters.
    """
    if detected_char and detected_char != expected_char:
        return f"I see you wrote '{detected_char}', but we were looking for '{expected_char}'. Let's try that letter again!"

    # No detection or wrong character
    if confidence_tier == "illegible":
        return f"Your {expected_char} needs to be clearer. Try writing it bigger and slower."
    elif confidence_tier == "unclear":
        return f"That's almost there! Make your {expected_char} a bit neater and try again."
    else:
        return f"I couldn't read your letter clearly. Try writing '{expected_char}' more carefully."


def evaluate_clip_quality_with_timeout(image_pil: Image.Image, expected_char: str) -> Tuple[int, str, str]:
    """
    Non-blocking CLIP quality evaluation with timeout protection.
    Returns default values if CLIP is not ready or times out.
    """
    if not USE_CLIP or not ensure_clip_loaded():
        return 75, "Good", "Nice work! Try to make it a bit neater."

    # Create result container for thread communication
    result = {"score": 75, "label": "Good", "feedback": "Nice work! Try to make it a bit neater."}

    def _clip_worker():
        try:
            score, label, feedback = evaluate_quality_with_clip(image_pil, expected_char)
            result.update({"score": score, "label": label, "feedback": feedback})
        except Exception as e:
            logger.warning("[CLIP_TIMEOUT] CLIP evaluation failed: %s", e)

    # Start CLIP evaluation in background thread
    clip_thread = threading.Thread(target=_clip_worker, daemon=True)
    clip_thread.start()

    # Wait with timeout
    clip_thread.join(timeout=CLIP_TIMEOUT_MS / 1000.0)

    if clip_thread.is_alive():
        logger.warning("[CLIP_TIMEOUT] CLIP evaluation timed out after %dms", CLIP_TIMEOUT_MS)
        # Thread is still running, return defaults
        return 75, "Good", "Nice work! Try to make it a bit neater."

    return result["score"], result["label"], result["feedback"]


def evaluate_image_vs_image(image_b64: str, expected_char: str, char_type: str = "letter") -> Dict:
    """
    CLIP-based evaluation pipeline for handwriting recognition.

    Uses CLIP for both character detection and quality assessment.
    """
    expected_char = expected_char.strip().upper()
    logger.info("[CLIP_EVAL] Evaluating: expected=%s", expected_char)

    # Decode image
    try:
        user_img_pil = decode_base64_image(image_b64)
    except Exception as e:
        logger.error("[CLIP_EVAL] Image decode failed: %s", e)
        return {
            "detected_letter": None,
            "ocr_confidence": 0.0,
            "legibility_status": "FAIL",
            "quality_score": 0,
            "quality_label": "Needs Improvement",
            "analysis_source": "ERROR",
            "feedback": "I couldn't process your drawing. Try writing on the canvas again."
        }

    # ============================================================================
    # STEP 1: CLIP CHARACTER DETECTION
    # ============================================================================
    detected_letter, clip_confidence = detect_letter_with_clip(user_img_pil)

    # Adjust threshold for lowercase letters (they match uppercase templates less well)
    is_lowercase = expected_char.islower()
    correctness_threshold = 0.75 if is_lowercase else 0.8

    # CLIP decides correctness
    if detected_letter == expected_char and clip_confidence >= correctness_threshold:
        legibility_status = "PASS"
        analysis_source = "CLIP"
        quality_score = 85  # Default good score
        quality_label = "Good"
        feedback = f"Great job on your {expected_char}! Keep practicing to make it even better."
    else:
        legibility_status = "FAIL"
        analysis_source = "CLIP"
        quality_score = 0
        quality_label = "Needs Improvement"
        if detected_letter and detected_letter != expected_char:
            feedback = f"I see you wrote '{detected_letter}'. Let's try writing '{expected_char}' together!"
        else:
            feedback = f"Let's work on your {expected_char}. Try writing it bigger and clearer."

    # ============================================================================
    # STEP 2: CLIP QUALITY ASSESSMENT
    # ============================================================================
    if legibility_status == "PASS":
        # Assess quality using CLIP
        clip_score, clip_label, clip_feedback = evaluate_quality_with_clip(user_img_pil, expected_char)

        # Use CLIP quality results
        quality_score = clip_score
        quality_label = clip_label
        feedback = clip_feedback

        logger.info("[CLIP_EVAL] Quality assessed: score=%d, label=%s", quality_score, quality_label)

    # ============================================================================
    # STEP 3: RETURN STANDARDIZED RESPONSE
    # ============================================================================
    return {
        "detected_letter": detected_letter,
        "ocr_confidence": round(clip_confidence, 2),  # Keep field name for compatibility
        "legibility_status": legibility_status,
        "quality_score": quality_score,
        "quality_label": quality_label,
        "analysis_source": analysis_source,
        "feedback": feedback
    }
def evaluate_digit_image_vs_image(image_b64: str, expected_digit: str) -> Dict:
    """Evaluate digit using CLIP template matching."""
    expected_digit = expected_digit.strip()
    logger.info("[DIGIT_EVAL] Evaluating digit: expected=%s", expected_digit)

    # Ensure CLIP loaded
    if not ensure_clip_loaded():
        return {"is_correct": False}

    # Decode image
    try:
        user_img_pil = decode_base64_image(image_b64)
    except Exception as e:
        logger.error("[DIGIT_EVAL] Image decode failed: %s", e)
        return {"is_correct": False}

    # Preprocess image
    try:
        clip_img_pil = preprocess_image_once(user_img_pil)
    except Exception as e:
        logger.error("[DIGIT_EVAL] Preprocessing failed: %s", e)
        return {"is_correct": False}

    # Embed with CLIP
    try:
        user_embedding = embed_image_clip(clip_img_pil)
    except Exception as e:
        logger.error("[DIGIT_EVAL] CLIP embedding failed: %s", e)
        return {"is_correct": False}

    # Compare against ALL digits
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

        if not all_similarities:
            return {"is_correct": False}

        ranked = sorted(all_similarities.items(), key=lambda x: x[1], reverse=True)
        top_digit, top_sim = ranked[0]
        expected_sim = all_similarities.get(expected_digit, 0.0)

        # Simple confidence-based decision
        confidence = round(expected_sim * 100, 1)
        
        # Special threshold for digit 6
        if expected_digit == "6":
            min_confidence = 86.0
            good_confidence = 92.0
        else:
            min_confidence = 80.0
            good_confidence = 88.0
        
        if confidence >= min_confidence:
            # Generate feedback based on confidence level
            if confidence >= good_confidence:
                feedback = f"Amazing work on your {expected_digit}! You're a star! ⭐"
            else:
                feedback = f"Awesome job on your {expected_digit}! Keep practicing and you'll be perfect! 💪"
            
            return {
                "is_correct": True, 
                "confidence": confidence, 
                "formation": confidence, 
                "pressure": None,
                "feedback": feedback
            }
        else:
            # Incorrect but encouraging feedback
            feedback = f"You're getting there with your {expected_digit}! Try again and you'll get it! 🌟"
            return {
                "is_correct": False,
                "feedback": feedback
            }

    except Exception as e:
        logger.error("[DIGIT_EVAL] Comparison failed: %s", e)
        return {
            "is_correct": False,
            "feedback": "Keep trying! You're doing great! 💪"
        }
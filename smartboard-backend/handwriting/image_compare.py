"""
IMAGE vs IMAGE handwriting evaluation using CLIP embeddings.

STRICT evaluation:
- Only compare against expected character templates
- No cross-character comparison
- Return Correct/Incorrect with confidence
"""

import torch
import open_clip
import base64
import io
import os
import numpy as np
from PIL import Image
import logging

logger = logging.getLogger(__name__)

# -------- CLIP GLOBAL CACHE --------
_device = "cpu"
_model = None
_preprocess = None


def get_clip():
    """Get or load CLIP model (cached globally)."""
    global _model, _preprocess
    if _model is None:
        logger.info("[CLIP-IMG] Loading CLIP ViT-B-32 for image comparison...")
        _model, _, _preprocess = open_clip.create_model_and_transforms(
            "ViT-B-32",
            pretrained="openai",
            device=_device
        )
        _model.eval()
        logger.info("[CLIP-IMG] CLIP loaded successfully")
    return _model, _preprocess


def decode_base64_image(img_b64):
    """Decode base64 image string to PIL Image."""
    try:
        if "," in img_b64:
            header, encoded = img_b64.split(",", 1)
        else:
            encoded = img_b64
        img_bytes = base64.b64decode(encoded)
        return Image.open(io.BytesIO(img_bytes)).convert("RGB")
    except Exception as e:
        logger.error("[CLIP-IMG] Base64 decode failed: %s", e)
        raise


def embed_image(pil_img):
    """Embed PIL image using CLIP (normalized)."""
    model, preprocess = get_clip()
    img_tensor = preprocess(pil_img).unsqueeze(0)
    with torch.no_grad():
        emb = model.encode_image(img_tensor)
        emb = emb / emb.norm(dim=-1, keepdim=True)
    return emb


def cosine_similarity(emb_a, emb_b):
    """Compute cosine similarity between two embeddings."""
    return float((emb_a @ emb_b.T).cpu().numpy()[0][0])


def evaluate_image_vs_image(image_b64, expected_char, mode="alphabet"):
    """
    STRICT image-vs-image evaluation.
    
    Only compares user image against templates of the EXPECTED character.
    No cross-character comparison.
    
    Args:
        image_b64: Base64 encoded user image
        expected_char: Expected character (e.g., "A", "5")
        mode: "alphabet" or "digits"
    
    Returns:
        dict with:
            - is_correct: bool
            - confidence: float (0-100)
            - message: str
            - analysis_source: "image_vs_image"
            - debug: dict (optional)
    """
    logger.info("[CLIP-IMG] Evaluating %s against '%s' (%s mode)", 
                "image", expected_char, mode)
    
    try:
        # Decode and embed user image
        user_img = decode_base64_image(image_b64)
        user_emb = embed_image(user_img)
        logger.debug("[CLIP-IMG] User image embedded")
    except Exception as e:
        logger.error("[CLIP-IMG] User image embedding failed: %s", e)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "message": "Image embedding failed",
            "analysis_source": "image_vs_image",
            "debug": {"error": str(e)}
        }
    
    # Determine template directory
    base_dir = "static/letters" if mode == "alphabet" else "static/digits"
    char_dir = os.path.join(base_dir, expected_char.upper())
    
    logger.debug("[CLIP-IMG] Looking for templates in: %s", char_dir)
    
    # Check if directory exists
    if not os.path.exists(char_dir):
        logger.warning("[CLIP-IMG] Template directory not found: %s", char_dir)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "message": "Template not found",
            "analysis_source": "image_vs_image",
            "debug": {"char_dir": char_dir}
        }
    
    # Load and score all templates
    scores = []
    template_files = []
    
    try:
        for file in os.listdir(char_dir):
            if not file.lower().endswith((".png", ".jpg", ".jpeg")):
                continue
            
            template_files.append(file)
            tpl_path = os.path.join(char_dir, file)
            
            try:
                tpl_img = Image.open(tpl_path).convert("RGB")
                tpl_emb = embed_image(tpl_img)
                sim = cosine_similarity(user_emb, tpl_emb)
                scores.append(sim)
                logger.debug("[CLIP-IMG] Template %s: similarity=%.4f", file, sim)
            except Exception as e:
                logger.warning("[CLIP-IMG] Failed to process template %s: %s", file, e)
                continue
    
    except Exception as e:
        logger.error("[CLIP-IMG] Template directory read failed: %s", e)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "message": "Template loading failed",
            "analysis_source": "image_vs_image",
            "debug": {"error": str(e)}
        }
    
    # Guard against no valid templates
    if not scores:
        logger.warning("[CLIP-IMG] No valid templates found for %s", expected_char)
        return {
            "is_correct": False,
            "confidence": 0.0,
            "message": "No valid templates",
            "analysis_source": "image_vs_image",
            "debug": {"templates_found": len(template_files)}
        }
    
    # Determine correctness based on best score
    best_score = max(scores)
    avg_score = np.mean(scores)
    
    # Thresholds: stricter for digits (more precise), lenient for letters
    threshold = 0.75 if mode == "alphabet" else 0.78
    
    is_correct = best_score >= threshold
    confidence = round(best_score * 100, 2)
    
    message = "✓ Correct" if is_correct else "✗ Incorrect"
    
    logger.info("[CLIP-IMG] Result: %s (score=%.4f, threshold=%.2f)", 
                message, best_score, threshold)
    
    return {
        "is_correct": is_correct,
        "confidence": confidence,
        "message": message,
        "analysis_source": "image_vs_image",
        "debug": {
            "best_score": round(best_score, 4),
            "avg_score": round(avg_score, 4),
            "threshold": threshold,
            "templates_evaluated": len(scores),
            "templates_total": len(template_files)
        }
    }

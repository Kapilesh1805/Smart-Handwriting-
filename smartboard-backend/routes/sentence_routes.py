"""
SENTENCE WRITING MODULE - CLIP-BASED EVALUATION

Evaluates complete sentences using CLIP similarity against templates.
No letter segmentation or per-letter evaluation.
"""

from flask import Blueprint, request, jsonify
import cv2
import numpy as np
import base64
import os
from database import sessions_col, reports_col
from session_logger import log_handwriting_session
import logging
from clip_engine.clip_loader import get_clip, compute_clip_similarity
import torch
from PIL import Image

logger = logging.getLogger(__name__)

sentence_bp = Blueprint("sentence", __name__, url_prefix="/sentence")

# HARDCODED SENTENCES
SENTENCES = [
    "I can write",
    "I like apples",
    "We go home",
    "The cat runs"
]

# Sentence templates (assume these exist locally)
SENTENCE_TEMPLATES = {
    "I can write": [
        "templates/sentences/i_can_write/template1.png",
        "templates/sentences/i_can_write/template2.png",
        "templates/sentences/i_can_write/template3.png",
    ],
    "I like apples": [
        "templates/sentences/i_like_apples/template1.png",
        "templates/sentences/i_like_apples/template2.png",
        "templates/sentences/i_like_apples/template3.png",
    ],
    "We go home": [
        "templates/sentences/we_go_home/template1.png",
        "templates/sentences/we_go_home/template2.png",
        "templates/sentences/we_go_home/template3.png",
    ],
    "The cat runs": [
        "templates/sentences/the_cat_runs/template1.png",
        "templates/sentences/the_cat_runs/template2.png",
        "templates/sentences/the_cat_runs/template3.png",
    ]
}

# Cached CLIP embeddings (loaded at startup)
sentence_template_embeddings = {}

# Sentence-specific thresholds (HARD RULE)
SENTENCE_THRESHOLD = {
    "I can write": 0.85,
    "I like apples": 0.85,
    "The cat runs": 0.85,
    "We go home": 0.85
}

def _compute_pressure_metric(image):
    """
    COMPUTE PRESSURE METRICS - RETURNS PRESSURE POINTS (0-100)

    Based on percentage of drawing pixels in the image.
    """
    try:
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Count drawing pixels (non-white)
        total_pixels = gray.size
        drawing_pixels = np.count_nonzero(gray < 200)  # Dark pixels

        # Pressure as percentage of drawing pixels
        pressure_percentage = (drawing_pixels / total_pixels) * 100

        # Scale to 0-100 score (clamp to valid range)
        pressure_points = min(100, max(0, pressure_percentage * 10))

        return int(pressure_points)

    except Exception as e:
        logger.error(f"[SENTENCE] Pressure computation error: {e}")
        # SAFE DEFAULT: Return medium pressure
        return 50

def load_sentence_template_embeddings():
    """
    Load and cache CLIP embeddings for all sentence templates at startup.
    This ensures templates are processed once and reused for all evaluations.
    """
    global sentence_template_embeddings
    
    if sentence_template_embeddings:
        return  # Already loaded
    
    logger.info("[SENTENCE] Loading template embeddings...")
    
    try:
        model, preprocess, _ = get_clip()
        
        for sentence, template_paths in SENTENCE_TEMPLATES.items():
            sentence_template_embeddings[sentence] = []
            
            for template_path in template_paths:
                if os.path.exists(template_path):
                    try:
                        # Load and preprocess template image
                        template_img = cv2.imread(template_path)
                        if template_img is not None:
                            # Convert BGR to RGB
                            template_rgb = cv2.cvtColor(template_img, cv2.COLOR_BGR2RGB)
                            pil_img = Image.fromarray(template_rgb)
                            
                            # Preprocess and embed
                            with torch.no_grad():
                                img_tensor = preprocess(pil_img).unsqueeze(0)
                                embedding = model.encode_image(img_tensor)
                                embedding = embedding / embedding.norm(dim=-1, keepdim=True)
                            
                            sentence_template_embeddings[sentence].append({
                                'path': template_path,
                                'embedding': embedding
                            })
                            logger.info(f"[SENTENCE] Loaded template: {template_path}")
                        else:
                            logger.warning(f"[SENTENCE] Failed to load template image: {template_path}")
                    except Exception as e:
                        logger.error(f"[SENTENCE] Error loading template {template_path}: {e}")
                else:
                    logger.warning(f"[SENTENCE] Template not found: {template_path}")
            
            if not sentence_template_embeddings[sentence]:
                logger.error(f"[SENTENCE] No valid templates loaded for sentence: {sentence}")
    
    except Exception as e:
        logger.error(f"[SENTENCE] Failed to load template embeddings: {e}")
        raise

# Load embeddings at module import
# Commented out for testing - will load on first request
# try:
#     load_sentence_template_embeddings()
# except Exception as e:
#     logger.warning(f"[SENTENCE] Failed to load template embeddings at startup: {e}")
#     logger.warning("[SENTENCE] Template embeddings will be loaded on first request")

@sentence_bp.route("/list", methods=["GET"])
def get_sentence_list():
    """
    Return the hardcoded list of sentences.
    No difficulty levels, just the 4 sentences.
    """
    return jsonify({
        "sentences": SENTENCES
    })

@sentence_bp.route("/analyze", methods=["POST"])
def analyze_sentence():
    """
    Analyze handwritten sentence using CLIP similarity against sentence templates.

    STRICT REQUIREMENTS:
    - Sentence-level CLIP similarity ONLY
    - NO extra validation logic (no ink coverage, stroke count, etc.)
    - Threshold-only decision: max_similarity <= SENTENCE_THRESHOLD[sentence]
    - Response format: Correct includes accuracy + pressure, Incorrect is minimal
    """
    try:
        data = request.json or {}
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        sentence = meta.get("sentence", "").strip()
        displayed_pressure = meta.get("displayed_pressure")

        # Validate inputs
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id required"}), 400
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if sentence not in SENTENCES:
            return jsonify({"msg": "error", "error": f"Invalid sentence: {sentence}"}), 400

        logger.info(f"[SENTENCE] Analyzing: '{sentence}' for child {child_id}")

        # Ensure template embeddings are loaded
        if not sentence_template_embeddings or sentence not in sentence_template_embeddings or not sentence_template_embeddings[sentence]:
            logger.info(f"[SENTENCE] Loading embeddings for sentence: {sentence}")
            try:
                load_sentence_template_embeddings()
            except Exception as e:
                logger.error(f"[SENTENCE] Failed to load template embeddings: {e}")
                return jsonify({"msg": "error", "error": "Template loading failed"}), 500

        # Compute CLIP similarity (sentence-level ONLY)
        max_similarity = _compute_sentence_similarity(image_b64, sentence)

        # THRESHOLD-ONLY DECISION (HARD RULE)
        threshold = SENTENCE_THRESHOLD[sentence]
        is_correct = (max_similarity <= threshold)

        logger.info(f"[SENTENCE] Similarity: {max_similarity:.4f}, Threshold: {threshold:.2f}, Correct: {is_correct}")

        # Log session (debugging only, never affects decisions)
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char="*",  # Placeholder
            predicted_char="*",  # Placeholder
            is_correct=is_correct,
            confidence=max_similarity,
            formation_score=None,
            pressure_score=pressure if is_correct else None,
            analysis_source="SENTENCE_TEMPLATE_CLIP_SIMILARITY",
            evaluation_mode="sentence",
            debug_info={
                "sentence": sentence,
                "max_similarity": max_similarity,
                "threshold": threshold,
                "is_correct": is_correct
            }
        )

        # STRICT RESPONSE FORMAT
        if is_correct:
            # Use displayed pressure if provided, otherwise compute from image
            if displayed_pressure is not None:
                pressure = displayed_pressure
            else:
                # Decode image for pressure calculation
                image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
                user_bytes = base64.b64decode(image_data)
                user_array = np.frombuffer(user_bytes, dtype=np.uint8)
                user_image = cv2.imdecode(user_array, cv2.IMREAD_COLOR)
                
                pressure = _compute_pressure_metric(user_image) if user_image is not None else 50
            accuracy = round(max_similarity * 100, 1)
            
            return jsonify({
                "status": "Correct",
                "accuracy": accuracy,
                "pressure": pressure
            })
        else:
            return jsonify({
                "status": "Incorrect"
            })

    except Exception as e:
        logger.error(f"[SENTENCE] Analysis error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"msg": "error", "error": str(e)}), 500

def _compute_sentence_similarity(user_image_b64, sentence):
    """
    Compute CLIP similarity between user image and sentence templates.
    
    Args:
        user_image_b64 (str): Base64 encoded user image
        sentence (str): The sentence being evaluated
        
    Returns:
        float: Maximum similarity score (0.0 to 1.0) across all templates
    """
    try:
        # Decode user image
        image_data = user_image_b64.split(",")[1] if "," in user_image_b64 else user_image_b64
        user_bytes = base64.b64decode(image_data)
        user_array = np.frombuffer(user_bytes, dtype=np.uint8)
        user_image = cv2.imdecode(user_array, cv2.IMREAD_COLOR)
        
        if user_image is None:
            logger.error("[SENTENCE] Failed to decode user image")
            return 0.0
        
        # Debug logging for image uniqueness verification
        user_height, user_width = user_image.shape[:2]
        user_pixel_sum = np.sum(user_image)
        logger.info(f"[SENTENCE] User image: {user_width}x{user_height}, pixels: {user_pixel_sum}")
        
        # Get CLIP model and preprocess
        model, preprocess, _ = get_clip()
        
        # Process user image
        user_rgb = cv2.cvtColor(user_image, cv2.COLOR_BGR2RGB)
        user_pil = Image.fromarray(user_rgb)
        
        with torch.no_grad():
            user_tensor = preprocess(user_pil).unsqueeze(0)
            user_embedding = model.encode_image(user_tensor)
            user_embedding = user_embedding / user_embedding.norm(dim=-1, keepdim=True)
        
        # Get cached template embeddings for this sentence
        if sentence not in sentence_template_embeddings or not sentence_template_embeddings[sentence]:
            logger.error(f"[SENTENCE] No cached embeddings for sentence: {sentence}")
            return 0.0
        
        max_similarity = 0.0
        template_embeddings = sentence_template_embeddings[sentence]
        
        for template_data in template_embeddings:
            template_embedding = template_data['embedding']
            
            # Compute cosine similarity
            similarity = float((user_embedding @ template_embedding.T).squeeze().item())
            
            # Clamp to [0, 1] range
            similarity = max(0.0, min(1.0, similarity))
            max_similarity = max(max_similarity, similarity)
            
            logger.info(f"[SENTENCE] Template {template_data['path']}: similarity {similarity:.4f}")
        
        logger.info(f"[SENTENCE] Max CLIP similarity: {max_similarity:.4f}")
        
        return max_similarity
        
    except Exception as e:
        logger.error(f"[SENTENCE] Similarity computation error: {e}")
        import traceback
        traceback.print_exc()
        return 0.0


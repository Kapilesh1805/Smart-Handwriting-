"""
Simple, clean handwriting evaluation routes using CLIP image embeddings.

Endpoints:
- GET /handwriting/health - Health check
- POST /handwriting/analyze - Routes to alphabet or number based on evaluation_mode
- POST /handwriting/analyze-number - Direct number evaluation
"""

from flask import Blueprint, request, jsonify
from handwriting.simple_clip_evaluator import evaluate_image_vs_image, evaluate_digit_image_vs_image
from handwriting.prewriting_evaluator import evaluate_prewriting_shape
from session_logger import log_handwriting_session
from database import sessions_col, reports_col
import logging
import sys
import os
import time

logger = logging.getLogger(__name__)

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

handwriting_bp = Blueprint("handwriting", __name__, url_prefix="/handwriting")

# Import clip_state (single source of truth for CLIP readiness)
import clip_state


def _wait_for_clip_ready(timeout: float = 30.0):
    """
    Block until CLIP is ready, with timeout.
    
    When a request arrives while CLIP is still warming up,
    sleep briefly and check again (non-busy loop).
    This ensures the frontend gets HTTP 200 with the result,
    not HTTP 202.
    
    Args:
        timeout: Maximum seconds to wait (default 30 seconds)
    
    Raises:
        TimeoutError if CLIP not ready after timeout
    """
    start_time = time.time()
    sleep_interval = 0.1  # Check every 100ms
    
    while not clip_state.is_ready():
        elapsed = time.time() - start_time
        if elapsed > timeout:
            logger.error("[WAIT_CLIP] Timeout waiting for CLIP (%.1fs)", elapsed)
            raise TimeoutError(f"CLIP warm-up exceeded {timeout}s timeout")
        
        time.sleep(sleep_interval)
    
    elapsed = time.time() - start_time
    if elapsed > 0.1:  # Only log if we actually waited
        logger.info("[WAIT_CLIP] ✅ CLIP ready after %.2fs", elapsed)


@handwriting_bp.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({"status": "ok", "service": "handwriting"}), 200


@handwriting_bp.route("/ping-number", methods=["GET"])
def ping_number():
    """Legacy ping endpoint for number route."""
    return jsonify({"status": "number route alive"}), 200


@handwriting_bp.route("/analyze", methods=["POST"])
def analyze_handwriting():
    """
    Main handwriting analysis endpoint.
    
    Routes to either alphabet or number evaluation based on evaluation_mode.
    
    CRITICAL: This endpoint BLOCKS until CLIP is ready.
    Never returns 202 to frontend. Always returns 200 with result.
    
    Expected JSON:
    {
        "child_id": "...",
        "image_b64": "...",
        "meta": {"letter": "A"},  # Expected character
        "evaluation_mode": "alphabet"  # or "number"
    }
    
    Returns:
    - 200 always (with result): { "is_correct": bool, "confidence": float, "formation": float|null, "pressure": float|null }
    """
    # BLOCK until CLIP is ready (do not return 202)
    try:
        _wait_for_clip_ready(timeout=30.0)
    except TimeoutError as e:
        logger.error("[ANALYZE] CLIP warm-up timeout: %s", e)
        return jsonify({
            "msg": "error",
            "error": "CLIP initialization timeout"
        }), 500
    
    logger.info("[ANALYZE] CLIP_READY = True, processing request")
    
    try:
        data = request.json or {}
        
        # Get evaluation mode
        evaluation_mode = data.get("evaluation_mode", "alphabet").lower()
        
        if evaluation_mode not in ["alphabet", "number"]:
            return jsonify({
                "msg": "error",
                "error": f"Invalid evaluation_mode '{evaluation_mode}'. Must be 'alphabet' or 'number'."
            }), 400
        
        # Route based on mode
        if evaluation_mode == "number":
            logger.info("🔢 Routing to number evaluation")
            return _evaluate_number(data)
        else:
            logger.info("📝 Routing to alphabet evaluation")
            return _evaluate_letter(data)
    
    except Exception as e:
        logger.error("Error in analyze route: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


@handwriting_bp.route("/analyze-number", methods=["POST"])
def analyze_number_route():
    """Direct route for number-only analysis.
    
    CRITICAL: This endpoint BLOCKS until CLIP is ready.
    Never returns 202 to frontend. Always returns 200 with result.
    """
    # BLOCK until CLIP is ready (do not return 202)
    try:
        _wait_for_clip_ready(timeout=30.0)
    except TimeoutError as e:
        logger.error("[ANALYZE-NUMBER] CLIP warm-up timeout: %s", e)
        return jsonify({
            "msg": "error",
            "error": "CLIP initialization timeout"
        }), 500
    
    logger.info("[ANALYZE-NUMBER] CLIP_READY = True, processing request")
    
    try:
        data = request.json or {}
        return _evaluate_number(data)
    except Exception as e:
        logger.error("Error in analyze_number_route: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


def _evaluate_letter(data: dict):
    """Evaluate a handwritten letter using CLIP template matching pipeline."""
    try:
        # Extract inputs
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_letter = meta.get("letter", "?").strip().upper()
        
        # Validate
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id required"}), 400
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if not expected_letter or len(expected_letter) != 1 or not expected_letter.isalpha():
            return jsonify({"msg": "error", "error": "Invalid expected letter"}), 400
        
        logger.info("[ALPHABET] Evaluating letter '%s' (child: %s)", expected_letter, child_id)
        
        # Evaluate using two-stage pipeline
        result = evaluate_image_vs_image(image_b64, expected_letter, "letter")
        
        # Log session to database
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char=expected_letter,
            predicted_char=expected_letter,  # No predicted letter returned in new pipeline
            is_correct=result.get("is_correct", False),
            confidence=result.get("confidence", 0.0),
            formation_score=result.get("formation"),
            pressure_score=result.get("pressure"),
            analysis_source="CLIP_TEMPLATE_MATCHING",
            evaluation_mode="alphabet",
            debug_info={}
        )
        
        logger.info("[ALPHABET] Session logged: %s", session_id)

        # Return stable response contract per spec
        is_correct = result.get("is_correct", False)
        confidence = result.get("confidence", 0.0)
        formation = result.get("formation")
        pressure = result.get("pressure")
        
        if is_correct:
            # Correct: include all fields
            return jsonify({
                "is_correct": True,
                "confidence": confidence,
                "formation": formation if formation is not None else confidence,
                "pressure": pressure
            }), 200
        else:
            # Incorrect: only include is_correct
            return jsonify({
                "is_correct": False
            }), 200
    
    except Exception as e:
        logger.error("Error in _evaluate_letter: %s", e)
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


def _evaluate_number(data: dict):
    """Evaluate a handwritten number using CLIP template verification pipeline."""
    try:
        # Extract inputs
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_digit = meta.get("letter", meta.get("digit", "?")).strip()
        
        # Validate
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id required"}), 400
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if not expected_digit or len(expected_digit) != 1 or not expected_digit.isdigit():
            return jsonify({"msg": "error", "error": "Invalid expected digit (0-9)"}), 400
        
        logger.info("[NUMBER] Evaluating digit '%s' (child: %s)", expected_digit, child_id)
        
        # Evaluate using image-vs-image pipeline (all digits 0-9)
        result = evaluate_digit_image_vs_image(image_b64, expected_digit)
        
        # Log session to database
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char=expected_digit,
            predicted_char=expected_digit,  # No predicted digit returned in verification pipeline
            is_correct=result.get("is_correct", False),
            confidence=result.get("confidence", 0.0),
            formation_score=result.get("formation"),
            pressure_score=result.get("pressure"),
            analysis_source="CLIP_TEMPLATE_VERIFICATION",
            evaluation_mode="number",
            debug_info={}
        )
        
        logger.info("[NUMBER] Session logged: %s", session_id)

        # Return stable response contract per spec
        is_correct = result.get("is_correct", False)
        confidence = result.get("confidence", 0.0)
        formation = result.get("formation")
        pressure = result.get("pressure")
        
        if is_correct:
            # Correct: include all fields
            return jsonify({
                "is_correct": True,
                "confidence": confidence,
                "formation": formation if formation is not None else confidence,
                "pressure": pressure
            }), 200
        else:
            # Incorrect: only include is_correct
            return jsonify({
                "is_correct": False
            }), 200
    
    except Exception as e:
        logger.error("Error in _evaluate_number: %s", e)
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


# ============================================================================
# PRE-WRITING EVALUATION (SEPARATE ISOLATED SYSTEM)
# ============================================================================

@handwriting_bp.route("/prewriting-evaluate", methods=["POST"])
def _evaluate_prewriting():
    """
    Evaluate pre-writing motor skills (line, curve, circle, square, zigzag).
    
    COMPLETELY ISOLATED from handwriting recognition (CLIP).
    Uses OpenCV geometry analysis only.
    
    Request:
    {
        "image_b64": base64-encoded canvas image,
        "expected_shape": "line" | "curve" | "circle" | "square" | "zigzag",
        "child_id": optional for logging
    }
    
    Response:
    {
        "is_correct": true/false,
        "score": 0-100,
        "feedback": string
    }
    """
    
    try:
        data = request.get_json()
        image_b64 = data.get("image_b64", "")
        expected_shape = data.get("expected_shape", "").strip().lower()
        child_id = data.get("child_id", "unknown")
        
        # Validate
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if not expected_shape:
            return jsonify({"msg": "error", "error": "expected_shape required"}), 400
        
        valid_shapes = {"line", "curve", "circle", "square", "zigzag"}
        if expected_shape not in valid_shapes:
            return jsonify({"msg": "error", "error": f"Invalid shape. Supported: {', '.join(valid_shapes)}"}), 400
        
        logger.info("[PREWRITING] Evaluating %s for child: %s", expected_shape, child_id)
        
        # Evaluate using pre-writing motor skills evaluator
        result = evaluate_prewriting_shape(image_b64, expected_shape)
        
        logger.info("[PREWRITING] Result: is_correct=%s, score=%.1f, feedback=%s",
                   result.get("is_correct"), result.get("score"), result.get("feedback"))
        
        return jsonify({
            "is_correct": result.get("is_correct", False),
            "score": result.get("score", 0.0),
            "feedback": result.get("feedback", "Error evaluating shape.")
        }), 200
    
    except Exception as e:
        logger.error("Error in _evaluate_prewriting: %s", e)
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


# Alias route for frontend compatibility
@handwriting_bp.route("/prewriting/analyze", methods=["POST"])
def _prewriting_analyze_alias():
    """
    Alias route for /handwriting/prewriting-evaluate (frontend compatibility).
    Routes to same evaluator but returns format expected by PreWritingSection.
    """
    try:
        data = request.get_json()
        image_b64 = data.get("image_b64", "")
        meta = data.get("meta", {})
        expected_shape = meta.get("shape", "").strip().lower()
        child_id = data.get("child_id", "unknown")
        
        # Validate
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if not expected_shape:
            return jsonify({"msg": "error", "error": "expected_shape required"}), 400
        
        # Evaluate using pre-writing evaluator
        result = evaluate_prewriting_shape(image_b64, expected_shape)
        
        logger.info("[PREWRITING_ALIAS] Result: is_correct=%s, score=%.1f",
                   result.get("is_correct"), result.get("score"))
        
        # Return in frontend-compatible format
        return jsonify({
            "is_correct": result.get("is_correct", False),
            "score": result.get("score", 0.0),
            "feedback": result.get("feedback", "Error evaluating shape."),
            "analysis": {
                "score": result.get("score", 0.0),
                "feedback": result.get("feedback", "")
            }
        }), 200
    
    except Exception as e:
        logger.error("Error in _prewriting_analyze_alias: %s", e)
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500

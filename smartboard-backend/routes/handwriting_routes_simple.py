"""
Simple, clean handwriting evaluation routes using CLIP image embeddings.

Endpoints:
- POST /handwriting/analyze - Routes to alphabet or number based on evaluation_mode
- POST /handwriting/analyze-number - Direct number evaluation
"""

from flask import Blueprint, request, jsonify
from handwriting.simple_clip_evaluator import evaluate_image_vs_image
from session_logger import log_handwriting_session
from database import sessions_col, reports_col
import logging
import os

logger = logging.getLogger(__name__)

handwriting_bp = Blueprint("handwriting", __name__, url_prefix="/handwriting")


@handwriting_bp.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({"status": "ok"}), 200


@handwriting_bp.route("/analyze", methods=["POST"])
def analyze_handwriting():
    """
    Main handwriting analysis endpoint.
    
    Routes to either alphabet or number evaluation based on evaluation_mode.
    
    Expected JSON:
    {
        "child_id": "...",
        "image_b64": "...",
        "meta": {"letter": "A"},  # Expected character
        "evaluation_mode": "alphabet"  # or "number"
    }
    """
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
            return evaluate_number(data)
        else:
            logger.info("📝 Routing to alphabet evaluation")
            return evaluate_letter(data)
    
    except Exception as e:
        logger.error("Error in analyze route: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


@handwriting_bp.route("/analyze-number", methods=["POST"])
def analyze_number_route():
    """Direct route for number-only analysis."""
    try:
        data = request.json or {}
        return evaluate_number(data)
    except Exception as e:
        logger.error("Error in analyze_number_route: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


def evaluate_letter(data: dict):
    """Evaluate a handwritten letter."""
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
        
        logger.info("[ALPHABET] Evaluating letter '%s'", expected_letter)
        
        # Evaluate
        result = evaluate_image_vs_image(image_b64, expected_letter, "letter")
        
        # Log session
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char=expected_letter,
            predicted_char=result.get("predicted_char", "?"),
            is_correct=result.get("is_correct", False),
            confidence=result.get("confidence", 0.0),
            formation_score=result.get("confidence"),
            pressure_score=None,
            analysis_source="simple_clip_evaluator",
            evaluation_mode="alphabet",
            debug_info=result.get("debug", {})
        )
        
        return jsonify({
            "msg": "analyzed",
            "analysis": {
                "predicted_letter": result.get("predicted_char"),
                "confidence": result.get("confidence"),
                "is_correct": result.get("is_correct"),
                "accuracy_score": result.get("confidence"),
                "formation_score": result.get("confidence"),
                "feedback": result.get("feedback"),
                "rule_applied": "simple_clip_evaluator"
            },
            "feedback": result.get("feedback"),
            "session_id": session_id
        }), 200
    
    except Exception as e:
        logger.error("Error in evaluate_letter: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500


def evaluate_number(data: dict):
    """Evaluate a handwritten number."""
    try:
        # Extract inputs
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_digit = meta.get("letter", "?").strip()
        
        # Validate
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id required"}), 400
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 required"}), 400
        if not expected_digit or len(expected_digit) != 1 or not expected_digit.isdigit():
            return jsonify({"msg": "error", "error": "Invalid expected digit (0-9)"}), 400
        
        logger.info("[NUMBER] Evaluating digit '%s'", expected_digit)
        
        # Evaluate
        result = evaluate_image_vs_image(image_b64, expected_digit, "digit")
        
        # Log session
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char=expected_digit,
            predicted_char=result.get("predicted_char", "?"),
            is_correct=result.get("is_correct", False),
            confidence=result.get("confidence", 0.0),
            formation_score=result.get("confidence"),
            pressure_score=None,
            analysis_source="simple_clip_evaluator",
            evaluation_mode="number",
            debug_info=result.get("debug", {})
        )
        
        return jsonify({
            "msg": "analyzed",
            "analysis": {
                "predicted_letter": result.get("predicted_char"),
                "confidence": result.get("confidence"),
                "is_correct": result.get("is_correct"),
                "accuracy_score": result.get("confidence"),
                "formation_score": result.get("confidence"),
                "feedback": result.get("feedback"),
                "rule_applied": "simple_clip_evaluator"
            },
            "feedback": result.get("feedback"),
            "session_id": session_id
        }), 200
    
    except Exception as e:
        logger.error("Error in evaluate_number: %s", e)
        return jsonify({
            "msg": "error",
            "error": str(e)
        }), 500

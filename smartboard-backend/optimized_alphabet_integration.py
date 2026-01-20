"""Compatibility bridge for alphabet evaluation.

This module provides backward-compatible access to the new CLIP-based
alphabet evaluation pipeline, replacing the old optimized_alphabet_integration logic.
"""

from flask import jsonify
import datetime
import logging

logger = logging.getLogger(__name__)


def analyze_handwriting_alphabet_v2(data, db_sessions_col=None, db_reports_col=None):
    """
    Evaluate a handwritten letter using CLIP + geometry.
    
    Called from Flask route with data dict.
    Delegates to the new handwriting.alphabet_pipeline analyzer.
    Logs results to database (if db_sessions_col provided).
    
    Args:
        data: Flask request dict with keys:
              - child_id: Child identifier
              - image_b64: Base64 encoded image
              - meta: Dict with 'letter' key
              - strokes: Stroke data (optional)
              - points: Stroke points (optional)
              - pressure_points: Pressure data (optional)
        db_sessions_col: MongoDB sessions collection (optional)
        db_reports_col: MongoDB reports collection (optional)
    
    Returns:
        (response_dict, http_status) tuple for Flask
    """
    try:
        from session_logger import log_handwriting_session
        
        # Extract parameters
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_letter = meta.get("letter", "Unknown")
        strokes_data = data.get("strokes") or data.get("points") or []
        pressure_points = data.get("pressure_points") or []
        
        # Validation
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id is required"}), 400
        
        if not expected_letter or len(expected_letter) != 1:
            return jsonify({"msg": "error", "error": "letter must be single character A-Z"}), 400
        
        print(f"[AlphabetV2] Starting evaluation for: {expected_letter}")
        
        # Import and call the new alphabet evaluation pipeline
        from handwriting.alphabet_pipeline import analyze_letter
        
        # Call analyzer
        ml_result = analyze_letter(image_b64, expected_letter)
        
        # Extract results
        predicted_letter = ml_result.get("letter", "?")
        is_correct = ml_result.get("is_correct", False)
        confidence = ml_result.get("confidence", 0.0)
        formation_score = ml_result.get("formation_score", 0.0)
        message = ml_result.get("message", "")
        
        # Build response
        analysis = {
            "predicted_letter": predicted_letter if is_correct else None,
            "expected_letter": expected_letter,
            "is_correct": is_correct,
            "confidence": confidence,
            "formation_score": formation_score,
            "accuracy_score": confidence,
            "feedback": message,
            "clip_available": True,
            "analysis_source": "CLIP"
        }
        
        # Log session (if DB available)
        session_id = None
        if db_sessions_col is not None:
            try:
                session_id = log_handwriting_session(
                    child_id=child_id,
                    expected_char=expected_letter,
                    predicted_char=predicted_letter,
                    is_correct=is_correct,
                    confidence=confidence,
                    formation_score=formation_score,
                    pressure_score=None,
                    analysis_source="CLIP",
                    evaluation_mode="alphabet",
                    debug_info={
                        "strokes_count": len(strokes_data),
                        "pressure_points_count": len(pressure_points)
                    }
                )
                print(f"[AlphabetV2] Session logged: {session_id}")
            except Exception as e:
                logger.error(f"[AlphabetV2] Failed to log session: {e}")
                session_id = None
        
        response = {
            "msg": "analyzed",
            "analysis": analysis,
            "feedback": message
        }
        if session_id:
            response["session_id"] = session_id
        
        return jsonify(response), 200
    
    except ValueError as ve:
        error_msg = f"Invalid input data: {str(ve)}"
        logger.error(f"[AlphabetV2] Validation Error: {error_msg}")
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "validation_error"
        }), 400
    
    except Exception as e:
        error_msg = f"Alphabet evaluation failed: {str(e)}"
        logger.error(f"[AlphabetV2] {error_msg}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "server_error"
        }), 500

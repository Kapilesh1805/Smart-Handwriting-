"""Compatibility bridge for number evaluation.

This module provides backward-compatible access to the new CLIP-based
number evaluation pipeline, replacing the old number_evaluation_v3 logic.
"""

import logging

logger = logging.getLogger(__name__)


def evaluate_number_with_clip_and_geometry(
    image_path: str,
    expected_digit: str,
    strokes_data: list,
    pressure_points: list
) -> dict:
    """Evaluate a handwritten digit using CLIP + geometry.

    - Delegates to the new handwriting.number_pipeline analyzer.
    - Normalizes output to expected dict format.
    - Returns safe fallback on any error.

    Args:
        image_path: Path to image file (may be unused by new pipeline).
        expected_digit: Expected digit (0-9).
        strokes_data: Stroke geometry data.
        pressure_points: Pressure point data.

    Returns:
        dict with keys: is_correct, predicted_digit, confidence,
                       formation_score, pressure_score, analysis_source,
                       message, match_type, model_used, model_name,
                       clip_similarity, clip_top_candidates, geometry_results
    """
    try:
        # Import the new number evaluation pipeline
        from handwriting.number_pipeline import analyze_number

        # Call the new analyzer
        result = analyze_number(image_path, expected_digit)

        # Normalize output to expected format
        is_correct = result.get("is_correct", False)
        predicted = result.get("digit", "?")
        confidence = result.get("confidence", 0.0)
        
        return {
            "is_correct": is_correct,
            "predicted_digit": predicted,
            "confidence": float(confidence),
            "formation_score": float(confidence),
            "pressure_score": 0.0,
            "analysis_source": "CLIP",
            "message": result.get("message", "Analysis complete"),
            "match_type": "Correct" if is_correct else "Incorrect",
            "model_used": True,
            "model_name": "CLIP",
            "clip_similarity": None,
            "clip_top_candidates": None,
            "geometry_results": None
        }

    except Exception as e:
        # Safe fallback with all required keys
        logger.warning(f"[NumberV3] Fallback: {e}")
        return {
            "is_correct": False,
            "predicted_digit": "?",
            "confidence": 0.0,
            "formation_score": 0.0,
            "pressure_score": 0.0,
            "analysis_source": "ERROR",
            "message": "Analysis failed - please try again",
            "match_type": "Incorrect",
            "model_used": False,
            "model_name": None,
            "clip_similarity": None,
            "clip_top_candidates": None,
            "geometry_results": None
        }

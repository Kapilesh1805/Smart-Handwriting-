"""Session logging module for handwriting analysis.

Handles storing analysis results to the database.
ML functions return analysis only (no DB interaction).
Routes call log_handwriting_session to persist results.

RULE 1: ML functions MUST NOT interact with database
RULE 2: Routes MUST call log_handwriting_session after analysis
RULE 3: All session documents use standardized schema
"""

import datetime
from database import sessions_col, reports_col
import logging

logger = logging.getLogger(__name__)


def log_handwriting_session(
    child_id: str,
    expected_char: str,
    predicted_char: str,
    is_correct: bool,
    confidence: float,
    formation_score: float = None,
    pressure_score: float = None,
    analysis_source: str = "CLIP",
    evaluation_mode: str = "alphabet",
    debug_info: dict = None
) -> str:
    """
    Log a handwriting analysis session to the database.
    
    This is the ONLY function that should persist analysis to database.
    ML functions must NOT call this - routes must.
    
    Args:
        child_id (str): Child identifier
        expected_char (str): Expected character (letter or digit)
        predicted_char (str): Predicted character
        is_correct (bool): Whether prediction is correct
        confidence (float): Confidence score (0.0-1.0 or 0-100)
        formation_score (float, optional): Formation quality score (0-100)
        pressure_score (float, optional): Pressure quality score (0-100)
        analysis_source (str): Source of analysis
                              Options: "CLIP", "GEOMETRY", "ERROR", "HYBRID"
        evaluation_mode (str): "alphabet" or "number"
        debug_info (dict, optional): Optional debug information
                                     Keys: rule_applied, model_used, model_name,
                                           clip_similarity, strokes_count, etc.
    
    Returns:
        str: session_id of inserted document
    
    Raises:
        Exception: If database operation fails
    
    Example:
        >>> session_id = log_handwriting_session(
        ...     child_id="abc123",
        ...     expected_char="A",
        ...     predicted_char="A",
        ...     is_correct=True,
        ...     confidence=0.95,
        ...     formation_score=90.0,
        ...     pressure_score=85.0,
        ...     analysis_source="CLIP",
        ...     evaluation_mode="alphabet"
        ... )
    """
    try:
        # Validate inputs
        if not isinstance(child_id, str) or not child_id.strip():
            raise ValueError("child_id must be non-empty string")
        
        if not isinstance(expected_char, str) or len(expected_char) != 1:
            raise ValueError("expected_char must be single character")
        
        if not isinstance(predicted_char, str) or len(predicted_char) != 1:
            raise ValueError("predicted_char must be single character")
        
        if not isinstance(is_correct, bool):
            raise ValueError("is_correct must be boolean")
        
        if not isinstance(confidence, (int, float)):
            raise ValueError("confidence must be number")
        
        # Normalize confidence to 0-100 range
        conf = float(confidence)
        if 0.0 <= conf <= 1.0:
            # Likely a 0-1 confidence, convert to 0-100
            conf = conf * 100.0
        elif conf > 100.0:
            # Clamp to 100
            conf = 100.0
        elif conf < 0.0:
            # Clamp to 0
            conf = 0.0
        
        # Normalize scores
        form_score = None
        if formation_score is not None:
            form_score = float(formation_score)
            if form_score > 100:
                form_score = 100.0
            elif form_score < 0:
                form_score = 0.0
        
        press_score = None
        if pressure_score is not None:
            press_score = float(pressure_score)
            if press_score > 100:
                press_score = 100.0
            elif press_score < 0:
                press_score = 0.0
        
        # Validate analysis source
        valid_sources = ["CLIP", "GEOMETRY", "ERROR", "HYBRID", "SENTENCE_AGGREGATION", "SENTENCE_CLIP", "SENTENCE_TEMPLATE_SIMILARITY"]
        if analysis_source not in valid_sources:
            logger.warning(f"[SessionLogger] Unknown analysis_source '{analysis_source}', using 'CLIP'")
            analysis_source = "CLIP"
        
        # Validate evaluation mode
        if evaluation_mode not in ["alphabet", "number", "sentence"]:
            logger.warning(f"[SessionLogger] Unknown evaluation_mode '{evaluation_mode}', using 'alphabet'")
            evaluation_mode = "alphabet"
        
        # Build session document with standardized schema
        session_doc = {
            "child_id": child_id.strip(),
            "expected_char": expected_char.upper(),
            "predicted_char": predicted_char.upper(),
            "is_correct": bool(is_correct),
            "confidence": conf,
            "formation_score": form_score,
            "pressure_score": press_score,
            "analysis_source": analysis_source,
            "evaluation_mode": evaluation_mode,
            "debug_info": debug_info or {},
            "timestamp": datetime.datetime.utcnow()
        }
        
        # Insert session document
        result = sessions_col.insert_one(session_doc)
        session_id = str(result.inserted_id)
        
        logger.debug(
            f"[SessionLogger] Session logged: {session_id} | "
            f"{expected_char} → {predicted_char} | "
            f"Correct: {is_correct} | Confidence: {conf:.1f}%"
        )
        
        # Insert report document (for report generation)
        try:
            report_doc = {
                "child_id": child_id.strip(),
                "session_id": session_id,
                "character": expected_char.upper(),
                "predicted": predicted_char.upper(),
                "is_correct": bool(is_correct),
                "accuracy": conf,
                "evaluation_mode": evaluation_mode,
                "generated_at": datetime.datetime.utcnow(),
                "analysis": {
                    "pressure_score": press_score,
                    "formation_score": form_score,
                }
            }
            reports_col.insert_one(report_doc)
        except Exception as e:
            logger.warning(f"[SessionLogger] Failed to insert report: {e}")
            # Don't raise - session is already saved
        
        return session_id
    
    except ValueError as ve:
        logger.error(f"[SessionLogger] Validation error: {ve}")
        raise
    
    except Exception as e:
        logger.error(f"[SessionLogger] Failed to log session: {e}")
        raise


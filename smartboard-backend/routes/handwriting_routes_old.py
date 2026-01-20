from flask import Blueprint, request, jsonify
from handwriting.simple_clip_evaluator import evaluate_image_vs_image
from session_logger import log_handwriting_session
from database import reports_col, sessions_col
import os
import logging
import sys

logger = logging.getLogger(__name__)

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

handwriting_bp = Blueprint("handwriting", __name__, url_prefix="/handwriting")


# Temporary health check for number route (quick verification)
@handwriting_bp.route("/ping-number", methods=["GET"])
def ping_number():
    return jsonify({"status": "number route alive"}), 200


@handwriting_bp.route("/analyze-number", methods=["POST"])
def analyze_number_route():
    """Direct route for number-only analysis.
    This allows frontend to POST directly to /handwriting/analyze-number.
    """
    try:
        data = request.json or {}
        return analyze_handwriting_number(data)
    except Exception as e:
        print(f"❌ [NumberRoute] Error: {e}")
        return jsonify({
            "msg": "error",
            "error": str(e),
            "type": "server_error"
        }), 500


# ═══════════════════════════════════════════════════════════════════════════
# HARD GATE: Route to appropriate evaluation pipeline
# ═══════════════════════════════════════════════════════════════════════════

@handwriting_bp.route("/analyze", methods=["POST"])
def analyze_handwriting():
    """
    HARD GATE: Routes to appropriate evaluation pipeline.
    
    Design principle: Intent (number vs alphabet) is decided by UI context,
    NOT inferred by ML.
    
    Expected JSON:
    {
        "child_id": "...",
        "image_b64": "...",
        "meta": {"letter": "A"},
        "evaluation_mode": "alphabet"  ← NEW: "alphabet" or "number"
    }
    """
    try:
        data = request.json or {}
        
        # ✅ HARD GATE: Check evaluation mode FIRST - BEFORE ANY OTHER PROCESSING
        evaluation_mode = data.get("evaluation_mode", "alphabet").lower()
        
        if evaluation_mode not in ["alphabet", "number"]:
            return jsonify({
                "msg": "error",
                "error": f"Invalid evaluation_mode '{evaluation_mode}'. Must be 'alphabet' or 'number'."
            }), 400
        
        # ✅ ROUTE TO APPROPRIATE PIPELINE
        if evaluation_mode == "number":
            print(f"\n🔢 [HARD GATE] Routing to ISOLATED NUMBER evaluation pipeline")
            return analyze_handwriting_number(data)
        else:
            print(f"\n📝 [HARD GATE] Routing to ALPHABET evaluation pipeline")
            return analyze_handwriting_alphabet(data)
    
    except Exception as e:
        print(f"❌ [HARD GATE] Error: {e}")
        return jsonify({
            "msg": "error",
            "error": str(e),
            "type": "gate_error"
        }), 500


# ═══════════════════════════════════════════════════════════════════════════
# NUMBER EVALUATION PIPELINE - COMPLETELY ISOLATED
# ═══════════════════════════════════════════════════════════════════════════

def analyze_handwriting_number(data):
    """
    NUMBER-ONLY EVALUATION PIPELINE (v3: CLIP + Geometry).

    CHARACTERISTICS:
    - Uses CLIP image–image similarity to digit templates
    - Geometry validates each CLIP candidate
    - Final decision combines CLIP ranking + geometric validation
    - Falls back to geometry-only if CLIP fails
    """
    try:
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_digit = meta.get("letter", "Unknown")
        strokes_data = data.get("strokes") or data.get("points") or []
        pressure_points = data.get("pressure_points") or []

        print(f"[NumberV3] Starting number evaluation pipeline")
        print(f"[NumberV3] Expected digit: '{expected_digit}'")
        print(f"[NumberV3] Strokes: {len(strokes_data)} points")

        # Validation
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id is required"}), 400

        if not expected_digit or not expected_digit.isdigit():
            return jsonify({
                "msg": "error",
                "error": f"Expected digit must be 0-9, got '{expected_digit}'"
            }), 400

        # Save image for CLIP evaluation
        image_path = None
        if image_b64:
            try:
                print(f"[NumberV3] Saving image for CLIP evaluation")
                image_path = save_base64_image(image_b64, prefix=f"num_{child_id}")
                print(f"✅ Image saved for CLIP: {image_path}")
            except Exception as e:
                print(f"⚠️ Could not save image for CLIP: {e}")
                image_path = None

        # Use new v3 pipeline if image available
        analysis = None
        if image_path and os.path.exists(image_path):
            try:
                print("[NumberV3] Using CLIP + Geometry evaluation")
                v3_result = evaluate_number_with_clip_and_geometry(
                    image_path=image_path,
                    expected_digit=expected_digit,
                    strokes_data=strokes_data,
                    pressure_points=pressure_points
                )

                # Backend contract: do not expose predicted digit in user-facing messages
                # when the result is incorrect. Keep predictions internal in logs only.
                is_correct_flag = v3_result.get('is_correct', False)
                predicted_for_logs = v3_result.get('predicted_digit')

                analysis = {
                    "predicted_letter": predicted_for_logs if is_correct_flag else None,
                    "match_type": v3_result.get('match_type', 'Incorrect'),
                    "is_match": is_correct_flag,
                    "is_correct": is_correct_flag,
                    "accuracy_score": v3_result.get('formation_score'),
                    "formation_score": v3_result.get('formation_score'),
                    "pressure_score": v3_result.get('pressure_score'),
                    "overall_score": v3_result.get('overall_score'),
                    "feedback": v3_result.get('message'),
                    "rule_applied": 'CLIP_Geometry_V3',
                    "model_used": v3_result.get('model_used', True),
                    "model_name": v3_result.get('model_name'),
                    "clip_available": True,
                    # recognized_char is internal; only expose when correct
                    "recognized_char": predicted_for_logs if is_correct_flag else None,
                    "expected_char": expected_digit,
                    "clip_similarity": v3_result.get('clip_similarity'),
                    "clip_top_candidates": v3_result.get('clip_top_candidates'),
                    "geometry_results": v3_result.get('geometry_results')
                }

            except Exception as e:
                print(f"❌ [NumberV3] Evaluation failed: {e} - falling back to geometry rules")
                import traceback
                traceback.print_exc()
                analysis = None
        else:
            print("[NumberV3] No image path available - falling back to geometry-only")
            analysis = None

        # If v3 pipeline failed, fall back to legacy geometry rules
        if analysis is None:
            print("[NumberV3] Falling back to geometry-only pipeline (legacy)")
            number_result = analyze_number(
                expected_digit=expected_digit,
                strokes_data=strokes_data,
                evaluation_mode='number'
            )

            analysis = {
                "predicted_letter": number_result.get('recognized_char', expected_digit),
                "match_type": number_result.get('match_type', 'Incorrect'),
                "is_match": number_result.get('is_match', False),
                "is_correct": number_result.get('is_correct', False),
                "accuracy_score": number_result.get('accuracy_score', 0.0),
                "formation_score": number_result.get('accuracy_score', 0.0),
                "pressure_score": None,
                "overall_score": number_result.get('accuracy_score', 0.0),
                "feedback": number_result.get('message'),
                "rule_applied": number_result.get('rule_applied'),
                "model_used": False,
                "model_name": None,
                "clip_available": False,
                "recognized_char": number_result.get('recognized_char'),
                "expected_char": number_result.get('expected_char', expected_digit)
            }

        # Extract key metrics for session logging
        predicted_digit = analysis.get("predicted_letter") or analysis.get("recognized_char", "?")
        is_correct_flag = analysis.get("is_correct", False)
        conf = analysis.get("accuracy_score", 0.0)
        form_score = analysis.get("formation_score")
        press_score = analysis.get("pressure_score")
        analysis_src = analysis.get("rule_applied", "CLIP_Geometry_V3")
        
        # Log session to database
        print(f"[NumberV3] Logging session: {expected_digit} → {predicted_digit} | Correct: {is_correct_flag}")
        debug_info = {
            "rule_applied": analysis.get("rule_applied"),
            "model_used": analysis.get("model_used"),
            "model_name": analysis.get("model_name"),
            "clip_available": analysis.get("clip_available"),
            "clip_similarity": analysis.get("clip_similarity"),
            "strokes_count": len(strokes_data),
            "pressure_points_count": len(pressure_points)
        }
        
        session_id = log_handwriting_session(
            child_id=child_id,
            expected_char=expected_digit,
            predicted_char=predicted_digit,
            is_correct=is_correct_flag,
            confidence=conf,
            formation_score=form_score,
            pressure_score=press_score,
            analysis_source=analysis_src,
            evaluation_mode="number",
            debug_info=debug_info
        )
        
        print(f"[NumberV3] Session stored: {session_id}")

        return jsonify({
            "msg": "analyzed",
            "analysis": analysis,
            "feedback": analysis.get('feedback'),
            "session_id": session_id
        }), 200

    except ValueError as ve:
        error_msg = f"Number evaluation validation failed: {str(ve)}"
        print(f"❌ [NumberV3] {error_msg}")
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "validation_error"
        }), 400

    except Exception as e:
        error_msg = f"Number evaluation failed: {str(e)}"
        print(f"❌ [NumberV3] {error_msg}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "server_error"
        }), 500


# ═══════════════════════════════════════════════════════════════════════════
# ALPHABET EVALUATION PIPELINE - USES CLIP AND VISUAL EQUIVALENCE
# ═══════════════════════════════════════════════════════════════════════════

def analyze_handwriting_alphabet(data):
    """
    ALPHABET-ONLY EVALUATION PIPELINE (v2 - OPTIMIZED).
    
    ✅ NEW: Geometry-first letter recognition
    ✅ NEW: CLIP restricted to family-filtered candidates
    ✅ NEW: Lowercase detection and handling
    ✅ NEW: Case-insensitive correctness rule
    ✅ NEW: 2-3x faster response times
    
    CHARACTERISTICS:
    - Uses geometry analysis FIRST (< 5ms)
    - Uses CLIP only for ambiguous cases (confidence < 0.75)
    - CLIP restricted to geometry-filtered candidates (max 3-4)
    - Proper lowercase letter handling
    - Full quality scoring
    - Formatted feedback
    """
    # Delegate to optimized implementation
    return analyze_handwriting_alphabet_v2(data, db_sessions_col=sessions_col, db_reports_col=reports_col)


def analyze_handwriting_alphabet_legacy(data):
    """
    DEPRECATED: Legacy alphabet evaluation (v1 - CLIP only).
    Kept for backward compatibility and testing.
    
    Use analyze_handwriting_alphabet() instead for the optimized v2 pipeline.
    """
    try:
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        expected_letter = meta.get("letter", "Unknown")
        
        print(f"[AlphabetEval] Starting alphabet evaluation")
        print(f"[AlphabetEval] Expected letter: '{expected_letter}'")
        
        # ✅ UX VALIDATION: Check if alphabet mode matches character type
        # If digit detected, provide soft guidance instead of error
        validation_result = validate_alphabet_mode(expected_letter, 'alphabet')
        
        if validation_result["status"] == "mode_mismatch":
            # SOFT RESPONSE: User guidance, not an error
            print(f"ℹ️ [UX] Mode mismatch: {validation_result['message']}")
            return jsonify({
                "msg": "mode_mismatch",
                "status": "mode_mismatch",
                "reason": "digit_detected",
                "message": validation_result["message"],
                "detected_character": validation_result["detected_character"],
                "suggested_mode": "number"
            }), 200  # 200 OK - this is user guidance, not an error
        
        elif validation_result["status"] == "error":
            # Hard error: Invalid mode (shouldn't happen due to hard gate, but check anyway)
            print(f"❌ [ERROR] {validation_result['message']}")
            return jsonify({
                "msg": "error",
                "error": validation_result["message"],
                "type": "invalid_mode"
            }), 400
        
        # Input validation
        if not child_id:
            return jsonify({"msg": "error", "error": "child_id is required"}), 400
        
        if not isinstance(child_id, str) or len(child_id) < 1:
            return jsonify({"msg": "error", "error": "child_id must be a non-empty string"}), 400
        
        if not image_b64:
            return jsonify({"msg": "error", "error": "image_b64 is required"}), 400
        
        if len(image_b64) > 5000000:
            return jsonify({"msg": "error", "error": "image is too large (max 5MB)"}), 400
        
        if not isinstance(meta, dict):
            return jsonify({"msg": "error", "error": "meta must be an object"}), 400
        
        if expected_letter and len(expected_letter) > 1:
            return jsonify({"msg": "error", "error": "letter must be a single character"}), 400
        
        # Save image
        image_filename = None
        image_path = None
        
        if image_b64:
            try:
                print(f"[AlphabetEval] Saving image")
                image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
                image_bytes = base64.b64decode(image_data)
                image_filename = f"{child_id}_{int(datetime.datetime.now().timestamp())}.png"
                image_path = os.path.join("uploads", image_filename)
                os.makedirs("uploads", exist_ok=True)
                with open(image_path, "wb") as f:
                    f.write(image_bytes)
                print(f"✅ Image saved: {image_path}")
            except Exception as e:
                print(f"❌ Image save error: {e}")
                image_path = None
        
        # Initialize results
        ml_results = {
            "pressure_score": None,
            "spacing_score": None,
            "formation_score": None,
            "accuracy_score": 0,
            "overall_score": None,
            "model_used": False,
            "model_name": None,
            "clip_similarity": None,
            "visual_score": None,
            "predicted_letter": None,
        }
        
        pressure_score = None
        formation_score = None
        formation_score_value = None
        clip_similarity = None
        predicted_letter = None
        
        # CLIP prediction
        if image_path and os.path.exists(image_path):
            try:
                print(f"[AlphabetEval] Loading CLIP...")
                ensure_clip_loaded()
                pred_letter, pred_conf, raw_sim = predict_letter_with_clip(image_path)
                predicted_letter = pred_letter
                ml_results["clip_raw_sim"] = raw_sim
                ml_results["predicted_letter"] = predicted_letter
                print(f"✅ CLIP predicted: '{predicted_letter}' (conf={pred_conf}, sim={raw_sim})")
            except Exception as e:
                print(f"❌ CLIP prediction failed: {e}")
                raise
        
        # Pressure scoring
        pressure_points = data.get("pressure_points") or []
        try:
            vals = []
            for p in pressure_points:
                v = p.get("pressure") if isinstance(p, dict) else p
                if v and v is not None:
                    vals.append(float(v))
            if vals:
                avg = sum(vals) / len(vals)
                if avg > 1.5:
                    avg = min(1.0, avg / 1024.0)
                pressure_score = round(max(0.0, min(100.0, avg * 100.0)), 2)
                print(f"✅ Pressure score: {pressure_score}%")
        except Exception as e:
            print(f"⚠️ Pressure calculation failed: {e}")
        
        # CLIP visual scoring
        if image_path and os.path.exists(image_path):
            try:
                ensure_clip_loaded()
                clip_sim = ml_results.get("clip_raw_sim")
                if clip_sim is None:
                    _, _, clip_sim = predict_letter_with_clip(image_path)
                
                sim01 = max(0.0, min(1.0, (float(clip_sim) + 1.0) / 2.0))
                formation_score_value = round(sim01 * 100.0, 2)
                
                if sim01 < 0.6:
                    formation_score = 'Poor'
                elif sim01 < 0.8:
                    formation_score = 'Average'
                else:
                    formation_score = 'Good'
                
                ml_results["clip_similarity"] = round(float(clip_sim), 4)
                ml_results["visual_score"] = formation_score_value
                ml_results["model_used"] = True
                ml_results["model_name"] = "open_clip"
                print(f"✅ Formation score: {formation_score} ({formation_score_value}%)")
            except Exception as e:
                print(f"⚠️ Formation scoring failed: {e}")
                raise
        
        # Character matching
        match_result = {
            'is_match': False,
            'match_type': 'Incorrect',
            'accuracy_score': 0.0,
            'message': 'No prediction available'
        }
        
        if predicted_letter and expected_letter:
            match_result = check_character_match(predicted_letter, expected_letter)
            print(f"✅ Match result: {match_result['match_type']} ({match_result['accuracy_score']}%)")
        
        # Compute overall score
        overall_score = 0
        try:
            if formation_score_value is not None and pressure_score is not None:
                overall_score = round(0.7 * float(formation_score_value) + 0.3 * float(pressure_score), 2)
            elif formation_score_value is not None:
                overall_score = round(float(formation_score_value), 2)
            elif pressure_score is not None:
                overall_score = round(float(pressure_score), 2)
        except:
            overall_score = 0
        
        ml_results.update({
            "pressure_score": pressure_score,
            "spacing_score": None,
            "formation_score": formation_score,
            "accuracy_score": match_result['accuracy_score'],
            "overall_score": overall_score,
            "predicted_letter": predicted_letter,
            "match_type": match_result['match_type'],
            "is_match": match_result['is_match']
        })
        
        # Generate feedback
        is_match = match_result['is_match']
        match_type = match_result['match_type']
        
        if not predicted_letter:
            letter_validation = f"ℹ️ Handwriting Analysis for '{expected_letter}'"
            quality_feedback = " Could not verify letter with model."
        elif not is_match:
            letter_validation = f"❌ Incorrect letter! You wrote '{predicted_letter}' instead of '{expected_letter}'. Try again!"
            quality_feedback = ""
        else:
            if match_type == 'Exact':
                letter_validation = f"✅ Correct! You wrote '{expected_letter}' perfectly."
            else:  # VisualMatch
                letter_validation = f"✅ Visually correct! '{predicted_letter}' is similar to '{expected_letter}'. Accepted."
            
            if overall_score < 50:
                quality_feedback = " Needs improvement - try more careful strokes."
            elif overall_score < 70:
                quality_feedback = " Good effort! Focus on consistency."
            elif overall_score < 85:
                quality_feedback = " Very good! Keep practicing!"
            else:
                quality_feedback = " Excellent work! Perfect formation!"
        
        feedback = f"{letter_validation}{quality_feedback}"
        
        # Store session
        session_doc = {
            "child_id": child_id,
            "letter": expected_letter,
            "predicted_letter": predicted_letter,
            "evaluation_mode": "alphabet",
            "timestamp": datetime.datetime.utcnow(),
            "analysis": {
                "pressure_score": pressure_score,
                "spacing_score": None,
                "formation_score": formation_score,
                "accuracy_score": match_result['accuracy_score'],
                "overall_score": overall_score,
                "feedback": feedback,
                "clip_available": ml_results.get('model_used', False),
                "predicted_letter": predicted_letter,
                "clip_similarity": ml_results.get('clip_similarity'),
                "visual_score": ml_results.get('visual_score'),
                "match_type": match_result['match_type'],
                "is_match": is_match
            },
            "image": image_filename
        }
        
        result = sessions_col.insert_one(session_doc)
        reports_col.insert_one({
            "child_id": child_id,
            "session_id": str(result.inserted_id),
            "summary": session_doc["analysis"],
            "generated_at": datetime.datetime.utcnow()
        })
        
        print(f"[AlphabetEval] Session stored: {result.inserted_id}")
        
        return jsonify({
            "msg": "analyzed",
            "analysis": session_doc["analysis"],
            "feedback": feedback,
            "session_id": str(result.inserted_id),
            "predicted_letter": predicted_letter
        }), 200
    
    except ValueError as ve:
        error_msg = f"Invalid input data: {str(ve)}"
        print(f"❌ [AlphabetEval] Validation Error: {error_msg}")
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "validation_error"
        }), 400
    
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(f"❌ [AlphabetEval] {error_msg}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "msg": "error",
            "error": error_msg,
            "type": "server_error"
        }), 500

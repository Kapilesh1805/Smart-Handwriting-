from flask import Blueprint, request, jsonify
from ml_model import predict_handwriting
from config import ML_MODEL_PATH
import os
import base64
import numpy as np
import datetime
import random
from database import reports_col, sessions_col


handwriting_bp = Blueprint("handwriting", __name__, url_prefix="/handwriting")


@handwriting_bp.route("/analyze", methods=["POST"])
def analyze_handwriting():
    """
    Accepts handwriting data for analysis.
    Expected JSON:
    {
        "child_id": "...",
        "image_b64": "...",       # optional
        "meta": {"letter": "A"}   # optional
    }
    """
    try:
        data = request.json or {}
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        letter = meta.get("letter", "Unknown")

        if not child_id:
            return jsonify({"msg": "error", "error": "child_id is required"}), 400

        # save handwriting image if available
        image_filename = None
        if image_b64:
            try:
                image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
                image_bytes = base64.b64decode(image_data)
                image_filename = f"{child_id}_{int(datetime.datetime.now().timestamp())}.png"
                image_path = os.path.join("uploads", image_filename)
                with open(image_path, "wb") as f:
                    f.write(image_bytes)
            except Exception as e:
                print(f"Image save error: {e}")

        # simulate ML analysis (will replace once model.h5 arrives)
        pressure_score = random.uniform(70, 95)
        spacing_score = random.uniform(60, 90)
        formation_score = random.uniform(65, 98)
        accuracy_score = (pressure_score + spacing_score + formation_score) / 3
        overall_score = round((pressure_score * 0.3 + spacing_score * 0.3 + formation_score * 0.4), 2)

        # letter-specific feedback
        feedback_map = {
            "A": "Excellent slant and alignment!",
            "B": "Good curves, try smoother top loop!",
            "C": "Neat round curve, keep it consistent!",
            "D": "Solid shape, tighten right edge slightly.",
        }
        feedback = feedback_map.get(letter.upper(), "Good effort! Keep practicing your letter formation.")

        # audio / motivational feedback
        from database import notifications_col
        notifications_col.insert_one({
            "title": f"Feedback for letter {letter}",
            "message": f"{feedback} Overall Score: {overall_score}%",
            "created_at": datetime.datetime.utcnow()
        })

        session_doc = {
            "child_id": child_id,
            "letter": letter,
            "timestamp": datetime.datetime.utcnow(),
            "analysis": {
                "pressure_score": pressure_score,
                "spacing_score": spacing_score,
                "formation_score": formation_score,
                "accuracy_score": accuracy_score,
                "overall_score": overall_score,
                "feedback": feedback,
                "model_used": os.path.exists(ML_MODEL_PATH)
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

        return jsonify({
            "msg": "analyzed",
            "analysis": session_doc["analysis"],
            "feedback": feedback,
            "session_id": str(result.inserted_id)
        })

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

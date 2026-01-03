import os
from flask import request
from werkzeug.utils import secure_filename
from config import UPLOAD_FOLDER
from flask import Blueprint, jsonify

prewriting_bp = Blueprint("prewriting", __name__, url_prefix="/prewriting")

@prewriting_bp.route("/list", methods=["GET"])
def get_prewriting_list():
    """
    Returns a static list of pre-writing exercises.
    Later you can store these in MongoDB if needed.
    """
    exercises = [
        {
            "id": 1,
            "title": "Vertical Lines",
            "description": "Draw straight vertical lines from top to bottom within the guide lines.",
            "difficulty": "Easy",
            "image": "https://example.com/images/vertical_lines.png"
        },
        {
            "id": 2,
            "title": "Horizontal Lines",
            "description": "Draw straight horizontal lines from left to right.",
            "difficulty": "Easy",
            "image": "https://example.com/images/horizontal_lines.png"
        },
        {
            "id": 3,
            "title": "Circles Practice",
            "description": "Draw circles within the boxes, maintaining equal size and spacing.",
            "difficulty": "Medium",
            "image": "https://example.com/images/circles.png"
        },
        {
            "id": 4,
            "title": "Diagonal Lines",
            "description": "Practice drawing diagonal lines from top-left to bottom-right and vice versa.",
            "difficulty": "Medium",
            "image": "https://example.com/images/diagonal.png"
        },
        {
            "id": 5,
            "title": "Curve Tracing",
            "description": "Trace over curved shapes to improve wrist movement control.",
            "difficulty": "Hard",
            "image": "https://example.com/images/curves.png"
        }
    ]

    return jsonify({"msg": "success", "exercises": exercises})

ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg"}

def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

# 🖼️ Upload prewriting exercise image
@prewriting_bp.route("/upload", methods=["POST"])
def upload_prewriting_image():
    """
    Uploads an image for prewriting exercise.
    Accepts form-data: { "file": <image_file> }
    """
    try:
        if "file" not in request.files:
            return jsonify({"msg": "error", "error": "No file part in request"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"msg": "error", "error": "No file selected"}), 400

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            file.save(save_path)
            return jsonify({"msg": "upload successful", "filename": filename, "path": save_path}), 201
        else:
            return jsonify({"msg": "error", "error": "Invalid file type (only png/jpg/jpeg allowed)"}), 400
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# ❌ Delete uploaded prewriting image
@prewriting_bp.route("/delete/<filename>", methods=["DELETE"])
def delete_prewriting_image(filename):
    """
    Deletes a prewriting exercise image by filename.
    """
    try:
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        if os.path.exists(file_path):
            os.remove(file_path)
            return jsonify({"msg": "file deleted", "filename": filename}), 200
        else:
            return jsonify({"msg": "error", "error": "File not found"}), 404
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

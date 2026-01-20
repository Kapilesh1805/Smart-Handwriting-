import os
import base64
import datetime
import cv2
import numpy as np
from flask import request
from werkzeug.utils import secure_filename
from config import UPLOAD_FOLDER
from flask import Blueprint, jsonify
from database import reports_col, sessions_col
from PIL import Image, ImageDraw

# ============================================================================
# PRE-WRITING MODULE - COMPLETE ISOLATION
# ============================================================================
# NO CLIP imports, NO character recognition, NO writing-interface logic
# This module is 100% independent of handwriting recognition systems

prewriting_bp = Blueprint("prewriting", __name__, url_prefix="/prewriting")

# Shape templates directory (one canonical template per shape)
TEMPLATES_DIR = "templates"

# Supported shapes (UI-selected only, never predicted)
SUPPORTED_SHAPES = {
    "LINES", "CURVES", "CIRCLES", "TRIANGLE", "SQUARE", "ZIGZAG"
}

# ============================================================================
# FINAL PRE-WRITING ANALYSIS PIPELINE
# ============================================================================

@prewriting_bp.route("/analyze", methods=["POST"])
def analyze_prewriting():
    """
    FINAL CLEAN PRE-WRITING ANALYSIS PIPELINE

    COMPLETE ISOLATION: No CLIP, no character recognition, no writing logic
    UNIFIED PROCESSING: Same pipeline for all shapes
    CONTOUR NORMALIZATION: Critical for small matchShapes scores

    Pipeline:
    1. Extract and filter child contour (area-based)
    2. Normalize contour (center + scale)
    3. Load and normalize canonical template
    4. Compare shapes with cv2.matchShapes
    5. Map score to accuracy (specific rules)
    6. Compute metrics only if correct
    7. Return clean response

    Input: {child_id, image_b64, meta: {shape}}
    Output: Clean JSON with conditional metrics
    """
    try:
        data = request.json or {}
        child_id = data.get("child_id")
        image_b64 = data.get("image_b64")
        meta = data.get("meta", {})
        selected_shape = meta.get("shape", "").strip().upper()

        # Validate inputs
        if not selected_shape or selected_shape not in SUPPORTED_SHAPES:
            return jsonify({"msg": "error", "error": f"Invalid shape: {selected_shape}"}), 400

        if not child_id:
            return jsonify({"msg": "error", "error": "child_id required"}), 400

        print(f"\n{'='*60}")
        print(f"FINAL PRE-WRITING ANALYSIS: {selected_shape}")
        print(f"{'='*60}")

        # ========================================================================
        # STEP 1: UNIFIED CONTOUR EXTRACTION WITH RELAXED FILTERING + FALLBACK
        # ========================================================================
        child_contour = _extract_filtered_contour(image_b64)
        if child_contour is None:
            print("❌ No contours detected at all")
            return _build_incorrect_response()

        # ========================================================================
        # STEP 2: CONTOUR NORMALIZATION (CRITICAL FOR SMALL SCORES)
        # ========================================================================
        normalized_child = _normalize_contour(child_contour)

        # ========================================================================
        # STEP 3: LOAD AND NORMALIZE CANONICAL TEMPLATE
        # ========================================================================
        normalized_template = _load_normalized_template(selected_shape)
        if normalized_template is None:
            print(f"❌ No template found for {selected_shape}")
            return _build_incorrect_response()

        # ========================================================================
        # STEP 4: RULE-BASED SHAPE CORRECTNESS EVALUATION
        # ========================================================================
        match_score = cv2.matchShapes(normalized_child, normalized_template, cv2.CONTOURS_MATCH_I1, 0)

        # Apply specific accuracy mapping (keeps scores small and meaningful)
        accuracy = _map_score_to_accuracy(match_score)

        # RULE-BASED CORRECTNESS: Different logic for stroke vs closed shapes
        if selected_shape.upper() in STROKE_SHAPES:
            # Stroke shapes: Use empirical score ranges (ignore accuracy threshold)
            is_correct = _is_correct_stroke_shape(selected_shape, match_score)
            print(f"✓ Stroke shape {selected_shape}: score={match_score:.4f}, correct={is_correct}")
        else:
            # Closed shapes: Use existing accuracy-based logic
            is_correct = (accuracy >= 65)
            print(f"✓ Closed shape {selected_shape}: accuracy={accuracy}%, correct={is_correct} (≥65% threshold)")

        print(f"✓ Normalized match score: {match_score:.4f}")
        print(f"✓ Mapped accuracy: {accuracy}%")
        print(f"✓ Final correctness: {is_correct}")

        # ========================================================================
        # STEP 5: CONDITIONAL METRICS COMPUTATION
        # ========================================================================
        if is_correct:
            # Load original image for metrics computation
            image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
            image_bytes = base64.b64decode(image_data)
            image_array = np.frombuffer(image_bytes, dtype=np.uint8)
            image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

            pressure_points, pressure_rank = _compute_pressure_metric(image)
            shape_formation = _assess_shape_formation(child_contour, normalized_template)

            print(f"✓ Pressure points: {pressure_points}, rank: {pressure_rank}")
            print(f"✓ Shape formation: {shape_formation}")

            return _build_correct_response(accuracy, pressure_points, pressure_rank, shape_formation)
        else:
            return _build_incorrect_response()

    except Exception as e:
        print(f"❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"msg": "error", "error": str(e)}), 500

# Shape groupings for rule-based evaluation
STROKE_SHAPES = {"LINES", "CURVES", "ZIGZAG"}
CLOSED_SHAPES = {"CIRCLES", "TRIANGLE", "SQUARE"}

def _is_correct_stroke_shape(shape, normalized_score):
    """
    RULE-BASED CORRECTNESS FOR STROKE SHAPES

    Uses empirical score ranges instead of accuracy thresholds.
    Prioritizes motor intent over geometric precision.
    """
    shape_upper = shape.upper()

    if shape_upper == "LINES":
        return normalized_score <= 1.5
    elif shape_upper == "CURVES":
        return normalized_score <= 6.0
    elif shape_upper == "ZIGZAG":
        return normalized_score <= 11
    else:
        return False

def _extract_filtered_contour(image_b64):
    """
    RELAXED IMAGE PREPROCESSING AND CONTOUR EXTRACTION WITH SAFE FALLBACK

    1. Decode base64 → BGR image
    2. Convert to grayscale
    3. Apply Gaussian blur
    4. Apply OTSU binary inverse threshold
    5. Extract contours with RETR_EXTERNAL
    6. Filter by relaxed area ratio (0.001 - 0.90)
    7. SAFE FALLBACK: If no contour passes filter, select largest from all contours
    8. Always return ONE contour (never None for valid drawings)
    """
    try:
        # 1. Decode base64 → BGR image
        image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
        image_bytes = base64.b64decode(image_data)
        image_array = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

        if image is None:
            return None

        # 2. Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # 3. Apply Gaussian blur (reduces noise)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # 4. Apply OTSU binary inverse threshold
        _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

        # 5. Extract contours with RETR_EXTERNAL
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            return None

        # 6-7. RELAXED AREA FILTERING + SAFE FALLBACK
        total_area = image.shape[0] * image.shape[1]
        min_area = 0.001 * total_area  # 0.1% - allows thin strokes (lines)
        max_area = 0.90 * total_area   # 90% - prevents background selection

        valid_contours = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if min_area <= area <= max_area:
                valid_contours.append(contour)

        # SAFE FALLBACK: Never fail for valid drawings
        if not valid_contours:
            print(f"⚠️  No contour passed area filter, using largest contour as fallback")
            # Select largest contour from ALL detected contours (safe fallback)
            selected_contour = max(contours, key=cv2.contourArea)
            selected_area = cv2.contourArea(selected_contour)
            print(f"✓ Fallback selected contour with area: {selected_area:.1f} ({selected_area/total_area*100:.3f}%)")
        else:
            # Select largest from valid contours
            selected_contour = max(valid_contours, key=cv2.contourArea)

        return selected_contour

    except Exception as e:
        print(f"❌ Contour extraction error: {e}")
        return None


def _normalize_contour(contour):
    """
    CONTOUR NORMALIZATION (CRITICAL FOR SMALL MATCHSHAPES SCORES)

    Before cv2.matchShapes, contours MUST be normalized:
    1. Convert to float32
    2. Center to origin (subtract centroid)
    3. Normalize by scale (L2 norm)

    This prevents matchShapes from returning huge scores.
    """
    try:
        # Convert to float32
        contour = contour.astype(np.float32)

        # Calculate centroid
        moments = cv2.moments(contour)
        if moments['m00'] == 0:
            return contour

        cx = moments['m10'] / moments['m00']
        cy = moments['m01'] / moments['m00']

        # Center to origin
        centered = contour - np.array([cx, cy])

        # Normalize by scale (L2 norm)
        norm = np.linalg.norm(centered)
        if norm > 0:
            normalized = centered / norm
        else:
            normalized = centered

        return normalized.astype(np.float32)

    except Exception as e:
        print(f"❌ Contour normalization error: {e}")
        return contour


def _load_normalized_template(shape_name):
    """
    LOAD PRE-NORMALIZED TEMPLATE CONTOUR

    - Exactly ONE template per shape
    - Templates stored as normalized contours (.npy files)
    - No runtime normalization needed
    - Ready for direct matchShapes comparison
    """
    try:
        template_path = os.path.join(TEMPLATES_DIR, f"{shape_name.lower()}_canonical.npy")

        if not os.path.exists(template_path):
            print(f"❌ Template not found: {template_path}")
            return None

        # Load pre-normalized contour from .npy file
        normalized_template = np.load(template_path)

        return normalized_template.astype(np.float32)

    except Exception as e:
        print(f"❌ Template loading error: {e}")
        return None


def _map_score_to_accuracy(match_score):
    """
    SPECIFIC ACCURACY MAPPING FOR ALL SHAPES

    Converts normalized matchShapes score to accuracy percentage.
    This mapping ensures small scores produce meaningful accuracy values.

    Score ranges:
    - <= 0.10 → 90% (excellent match)
    - <= 0.20 → 80% (good match)
    - <= 0.30 → 70% (fair match)
    - <= 0.40 → 60% (poor match)
    - > 0.40 → 40% (very poor match)
    """
    if match_score <= 0.10:
        return 90
    elif match_score <= 0.20:
        return 80
    elif match_score <= 0.30:
        return 70
    elif match_score <= 0.40:
        return 60
    else:
        return 40


def _compute_pressure_metric(image):
    """
    COMPUTE PRESSURE METRICS - BOTH POINTS AND RANK

    Returns tuple: (pressure_points, pressure_rank)

    pressure_points: 0-100 normalized score
    pressure_rank: 0-2 child-friendly rank

    NEVER returns null - always provides safe defaults.
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

        # Map to child-friendly rank (0-2)
        if pressure_points < 34:
            pressure_rank = 0  # Light
        elif pressure_points < 67:
            pressure_rank = 1  # Medium
        else:
            pressure_rank = 2  # Firm

        return int(pressure_points), pressure_rank

    except Exception as e:
        print(f"❌ Pressure computation error: {e}")
        # SAFE DEFAULT: Return medium pressure (never null)
        return 50, 1  # 50 points, rank 1 (Medium)


def _assess_shape_formation(child_contour, template_contour):
    """
    ASSESS SHAPE FORMATION QUALITY

    Compares area and perimeter ratios between child and template.
    Returns "Fair", "Good", or "Excellent" based on similarity.
    """
    try:
        # Compare areas
        child_area = cv2.contourArea(child_contour)
        template_area = cv2.contourArea(template_contour)

        if template_area == 0:
            return "Fair"

        area_ratio = min(child_area, template_area) / max(child_area, template_area)

        # Compare perimeters
        child_perimeter = cv2.arcLength(child_contour, True)
        template_perimeter = cv2.arcLength(template_contour, True)

        if template_perimeter == 0:
            return "Fair"

        perimeter_ratio = min(child_perimeter, template_perimeter) / max(child_perimeter, template_perimeter)

        # Combined score
        formation_score = (area_ratio + perimeter_ratio) / 2

        # Return formation quality
        if formation_score >= 0.85:
            return "Excellent"
        elif formation_score >= 0.7:
            return "Good"
        else:
            return "Fair"

    except Exception as e:
        print(f"❌ Shape formation assessment error: {e}")
        return "Fair"


def _build_correct_response(accuracy, pressure_points, pressure_rank, shape_formation):
    """Build clean response for correct shapes."""
    return jsonify({
        "is_correct": True,
        "shape_formation": shape_formation,
        "pressure_points": pressure_points,
        "pressure_rank": pressure_rank
    })


def _build_incorrect_response():
    """Build clean response for incorrect shapes."""
    return jsonify({
        "is_correct": False,
        "shape_formation": None,
        "pressure_points": None,
        "pressure_rank": None
    })


# ============================================================================
# LEGACY ROUTES (KEPT FOR COMPATIBILITY)
# ============================================================================

@prewriting_bp.route("/list", methods=["GET"])
def get_prewriting_list():
    """
    Returns a static list of pre-writing exercises.
    """
    exercises = [
        {"id": "lines", "name": "Lines", "description": "Practice drawing straight lines"},
        {"id": "curves", "name": "Curves", "description": "Practice drawing curved lines"},
        {"id": "circles", "name": "Circles", "description": "Practice drawing circles"},
        {"id": "triangle", "name": "Triangle", "description": "Practice drawing triangles"},
        {"id": "square", "name": "Square", "description": "Practice drawing squares"},
        {"id": "zigzag", "name": "Zigzag", "description": "Practice drawing zigzag lines"}
    ]
    return jsonify({"exercises": exercises})


@prewriting_bp.route("/upload", methods=["POST"])
def upload_prewriting_image():
    """
    Uploads an image for prewriting exercise.
    """
    try:
        if 'image' not in request.files:
            return jsonify({"msg": "error", "error": "No image file provided"}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({"msg": "error", "error": "No image selected"}), 400

        if file:
            filename = secure_filename(file.filename)
            file_path = os.path.join(UPLOAD_FOLDER, filename)
            os.makedirs(UPLOAD_FOLDER, exist_ok=True)
            file.save(file_path)

            return jsonify({
                "msg": "uploaded",
                "filename": filename,
                "path": file_path
            }), 200

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


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
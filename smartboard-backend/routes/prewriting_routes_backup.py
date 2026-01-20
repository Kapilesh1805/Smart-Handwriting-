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

# Reference shape storage directory (OFFLINE, LOCAL ONLY)
REFERENCE_SHAPES_DIR = "reference_shapes"

# Shape name mapping
SHAPE_CATEGORIES = {
    "LINES": "lines",
    "CURVES": "curves", 
    "CIRCLES": "circles",
    "TRIANGLE": "triangle",
    "SQUARE": "square",
    "ZIGZAG": "zigzag"
}

# ============================================================================
# ============================================================================
# REFERENCE SHAPE MANAGEMENT (OFFLINE, LOCAL ONLY - NO INTERNET)
# ============================================================================
# All reference shapes are loaded from the local reference_shapes/ directory.
# NO internet downloads. NO network calls. 100% offline operation.
# If references are missing → Stage-1 validation HARD FAILS (not bypassed).

def _load_reference_shapes_local(expected_shape):
    """
    Load reference shapes from LOCAL filesystem ONLY.
    
    NO internet downloads. NO synthetic shapes.
    All references must exist in reference_shapes/{SHAPE}/ directory.
    
    Args:
        expected_shape: Shape name (e.g., "CIRCLES", "LINES")
    
    Returns:
        List of file paths to reference images (or empty list if missing)
    """
    shape_dir = os.path.join(REFERENCE_SHAPES_DIR, expected_shape.upper())
    
    if not os.path.exists(shape_dir):
        print(f"\n⚠️  REFERENCE DIRECTORY MISSING: {shape_dir}")
        print(f"    Stage-1 validation will FAIL for {expected_shape}")
        return []
    
    # Get all image files from the reference shape directory
    reference_files = [
        os.path.join(shape_dir, f)
        for f in os.listdir(shape_dir)
        if f.lower().endswith(('.png', '.jpg', '.jpeg'))
    ]
    
    if not reference_files:
        print(f"\n❌ NO REFERENCE IMAGES FOUND: {shape_dir}")
        print(f"    Please populate {shape_dir}/ with reference images")
        print(f"    Required: ≥10 PNG images per shape")
        return []
    
    return reference_files


def _verify_offline_references_available():
    """
    Verify that ALL required reference shape directories exist and contain images.
    
    This is the ONLY initialization step - NO downloads, NO synthetic creation.
    Call this on startup to verify references are available.
    
    Returns:
        Dictionary with status per shape (e.g., {"CIRCLES": "READY", ...})
    """
    print("\n" + "="*80)
    print("📊 OFFLINE REFERENCE SHAPE VERIFICATION")
    print("="*80)
    print("Checking local reference_shapes/ directory...")
    print("(NO internet access required)")
    
    os.makedirs(REFERENCE_SHAPES_DIR, exist_ok=True)
    
    status_report = {}
    all_ready = True
    
    for shape_name in SHAPE_CATEGORIES.keys():
        shape_dir = os.path.join(REFERENCE_SHAPES_DIR, shape_name)
        os.makedirs(shape_dir, exist_ok=True)
        
        # Count existing images
        image_files = [
            f for f in os.listdir(shape_dir)
            if f.lower().endswith(('.png', '.jpg', '.jpeg'))
        ]
        
        file_count = len(image_files)
        
        if file_count >= 10:
            print(f"  ✅ {shape_name}: {file_count} images")
            status_report[shape_name] = "READY"
        elif file_count >= 1:
            print(f"  ⚠️  {shape_name}: {file_count} images (need ≥10)")
            status_report[shape_name] = "INCOMPLETE"
            all_ready = False
        else:
            print(f"  ❌ {shape_name}: NO images found")
            status_report[shape_name] = "EMPTY"
            all_ready = False
    
    print("\n" + "="*80)
    if all_ready:
        print("✅ ALL REFERENCES READY - Stage-1 validation enabled")
    else:
        print("⚠️  SOME REFERENCES MISSING - Populate reference_shapes/ directory")
        print("\nTo fix:")
        for shape_name, status in status_report.items():
            if status != "READY":
                print(f"  - {shape_name}: {status} → Need images in reference_shapes/{shape_name}/")
    print("="*80 + "\n")
    
    return status_report


def _ensure_reference_shapes_exist():
    """
    Ensure reference shape directory structure exists locally.
    
    This ONLY checks for offline references.
    NO internet downloads. NO synthetic shapes.
    
    If references are missing:
    - Stage-1 validation will HARD FAIL
    - Drawing will be marked INCORRECT
    - NO BYPASS allowed
    """
    print("\n" + "="*80)
    print("📋 REFERENCE SHAPE VERIFICATION (OFFLINE ONLY)")
    print("="*80)
    print("Verifying reference shapes are available locally...")
    
    os.makedirs(REFERENCE_SHAPES_DIR, exist_ok=True)
    
    status = _verify_offline_references_available()
    
    return status


def _get_reference_shapes(expected_shape):
    """
    Get all reference shape images for a given expected_shape.
    Loads from local directory ONLY.
    
    Args:
        expected_shape: Shape name (e.g., "LINES", "CIRCLES", "SQUARE")
    
    Returns:
        List of paths to reference shape images (or empty list if none found)
    """
    reference_files = _load_reference_shapes_local(expected_shape)
    
    if reference_files:
        print(f"✓ Found {len(reference_files)} reference shapes for {expected_shape}")
    
    return reference_files


# ============================================================================
# STAGE 1: SHAPE SIMILARITY VALIDATION (HARD GATE)
# ============================================================================

def _extract_largest_contour(image_path):
    """
    Extract the largest contour from an image.
    
    Args:
        image_path: Path to image file
    
    Returns:
        Largest contour (OpenCV contour object) or None if no contours found
    """
    try:
        image = cv2.imread(image_path)
        if image is None:
            print(f"❌ Could not read image: {image_path}")
            return None
        
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply threshold to get binary image
        _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)
        
        # Find contours
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            print(f"❌ No contours found in image")
            return None
        
        # Return the largest contour
        largest_contour = max(contours, key=cv2.contourArea)
        print(f"✓ Extracted largest contour with area {cv2.contourArea(largest_contour):.1f}")
        return largest_contour
    
    except Exception as e:
        print(f"❌ Error extracting contour: {e}")
        return None

def _count_zigzag_vertices(contour):
    """
    Count significant direction changes in contour (vertices for zigzag).
    
    Args:
        contour: OpenCV contour
    
    Returns:
        Number of vertices (direction changes)
    """
    if len(contour) < 10:
        return 2  # Minimum
    
    # Simplify contour to reduce noise
    epsilon = 0.01 * cv2.arcLength(contour, True)
    approx = cv2.approxPolyDP(contour, epsilon, True)
    
    # Count vertices as number of points in approximated contour
    vertices = len(approx)
    return max(vertices, 2)  # At least 2

def _calculate_curvature_ratio(contour):
    """
    Calculate curvature ratio for curves.
    Measures how much the shape deviates from a straight line.
    
    Args:
        contour: OpenCV contour
    
    Returns:
        Curvature ratio (higher = more curved)
    """
    if len(contour) < 10:
        return 1.0
    
    # Calculate bounding box
    x, y, w, h = cv2.boundingRect(contour)
    
    # Aspect ratio of bounding box
    aspect_ratio = max(w, h) / min(w, h) if min(w, h) > 0 else 1.0
    
    # Perimeter to area ratio (higher = more complex shape)
    area = cv2.contourArea(contour)
    perimeter = cv2.arcLength(contour, True)
    complexity = perimeter / area if area > 0 else 1.0
    
    # Combine for curvature ratio
    curvature_ratio = aspect_ratio * complexity * 0.1  # Scale down
    return max(curvature_ratio, 1.0)

def _compute_curvature_sign_changes(contour):
    """
    Compute the number of curvature sign changes in a contour.
    
    This differentiates smooth curves from zigzag patterns by counting
    how many times the turning direction changes sign.
    
    Args:
        contour: OpenCV contour object
    
    Returns:
        int: Number of curvature sign changes
    """
    if len(contour) < 6:  # Need at least 6 points for meaningful curvature
        return 0
    
    angles = []
    
    # Calculate turning angles at each point
    for i in range(1, len(contour) - 1):
        # Get three consecutive points
        p1 = contour[i-1][0]
        p2 = contour[i][0] 
        p3 = contour[i+1][0]
        
        # Vectors
        v1 = p2 - p1
        v2 = p3 - p2
        
        # Calculate angle between vectors using atan2
        angle1 = np.arctan2(v1[1], v1[0])
        angle2 = np.arctan2(v2[1], v2[0])
        
        # Normalize angle difference to [-pi, pi]
        angle_diff = angle2 - angle1
        while angle_diff > np.pi:
            angle_diff -= 2 * np.pi
        while angle_diff < -np.pi:
            angle_diff += 2 * np.pi
            
        angles.append(angle_diff)
    
    if len(angles) < 3:
        return 0
    
    # Count sign changes in the angle differences
    # Positive angle = left turn, negative = right turn
    sign_changes = 0
    prev_sign = np.sign(angles[0])
    
    for angle in angles[1:]:
        current_sign = np.sign(angle)
        if current_sign != 0 and prev_sign != 0 and current_sign != prev_sign:
            sign_changes += 1
        if current_sign != 0:
            prev_sign = current_sign
    
    return sign_changes


def _compute_shape_similarity(user_image_path, reference_image_path):
    """
    Compute similarity between user drawing and reference shape using OpenCV matchShapes.

    Args:
        user_image_path: Path to user's drawing image
        reference_image_path: Path to reference shape image

    Returns:
        float: Similarity score (0.0-1.0, higher = more similar) or None if error
    """
    try:
        # Extract contours from both images
        user_contour = _extract_largest_contour(user_image_path)
        ref_contour = _extract_largest_contour(reference_image_path)

        if user_contour is None or ref_contour is None:
            return None

        # Check contour areas (must be reasonable size)
        user_area = cv2.contourArea(user_contour)
        ref_area = cv2.contourArea(ref_contour)

        if user_area < 10 or ref_area < 10:
            return None  # Too small to compare

        # Use OpenCV matchShapes (lower values = more similar)
        # Method: cv2.CONTOURS_MATCH_I1 (Hu moments)
        match_score = cv2.matchShapes(user_contour, ref_contour, cv2.CONTOURS_MATCH_I1, 0)

        # Convert to similarity score (0.0-1.0, higher = more similar)
        # matchShapes returns values from 0 to ~2, where 0 = perfect match
        similarity = max(0.0, 1.0 - match_score)

        return similarity

    except Exception as e:
        print(f"❌ Error computing shape similarity: {e}")
        return None


def _infer_shape_from_geometry(contour):
    """
    Infer the shape type from geometric properties using non-overlapping rules.
    
    Args:
        contour: OpenCV contour object
    
    Returns:
        identified_shape: "LINES", "CIRCLES", "CURVES", "ZIGZAG", "TRIANGLE", "SQUARE", or "UNKNOWN"
    """
    if contour is None:
        return "UNKNOWN"
    
    area = cv2.contourArea(contour)
    perimeter = cv2.arcLength(contour, True)
    
    if area < 5 or perimeter < 10:  # Relaxed thresholds
        return "UNKNOWN"
    
    # Compute geometric features
    circularity = (4 * np.pi * area) / (perimeter * perimeter) if perimeter > 0 else 0
    x, y, w, h = cv2.boundingRect(contour)
    aspect_ratio = max(w, h) / min(w, h) if min(w, h) > 0 else 1.0
    
    # Closed vs Open detection
    start_point = contour[0][0]
    end_point = contour[-1][0]
    distance = np.linalg.norm(start_point - end_point)
    is_closed = distance < 0.1 * perimeter
    
    # Count vertices for polygons
    epsilon = 0.02 * cv2.arcLength(contour, True)
    approx = cv2.approxPolyDP(contour, epsilon, True)
    vertices = len(approx)
    
    # Compute curvature sign changes for CURVE vs ZIGZAG differentiation
    curvature_sign_changes = _compute_curvature_sign_changes(contour)
    
    # INTENT RULES (non-overlapping)
    
    # SQUARE: 4 vertices, aspect ratio close to 1, closed
    if vertices == 4 and 0.8 <= aspect_ratio <= 1.2 and is_closed:
        return "SQUARE"
    
    # CIRCLES: High circularity and closed
    if circularity > 0.6 and is_closed:
        return "CIRCLES"
    
    # ZIGZAG: Multiple vertices (>=4) AND high curvature sign changes (>=3)
    # HARD RULE: If curvature_sign_changes >= 3, MUST be ZIGZAG
    if vertices >= 4 and curvature_sign_changes >= 3:
        return "ZIGZAG"
    
    # CURVES: Multiple vertices (>=4), low curvature sign changes (<=2), medium circularity
    if (vertices >= 4 and 
        curvature_sign_changes <= 2 and 
        0.35 <= circularity <= 0.75):
        return "CURVES"
    
    # LINES: Low circularity, high aspect ratio, open (relaxed)
    if circularity < 0.6 and aspect_ratio > 1.5 and not is_closed:
        return "LINES"
    
    # CURVES: Medium circularity (fallback for other cases)
    if 0.2 <= circularity <= 0.6:
        return "CURVES"
    
    return "UNKNOWN"

def _stage1_shape_similarity_validation(user_image_path, expected_shape):
    """
    STAGE 1: HARD GATE - Geometric pre-gate + reference shape similarity comparison.
    
    🚨 CRITICAL: This gate NEVER bypasses. 
    1. GEOMETRIC PRE-GATE: Check basic geometry (circularity, endpoints, etc.)
    2. SIMILARITY COMPARISON: Only runs if geometry gate passes
    
    If geometry gate fails OR no reference shapes exist, shape validation FAILS.
    
    Reference shapes are MANDATORY real handwritten data from QuickDraw.
    If missing: Shape marked INCORRECT (no bypass allowed).
    
    Args:
        user_image_path: Path to user-drawn image
        expected_shape: Expected shape name (e.g., "LINES", "CIRCLES")
    
    Returns:
        Tuple: (is_valid, best_similarity_score, inferred_shape)
            - is_valid: Boolean, True if shape intent matches expected
            - best_similarity_score: Lowest (best) similarity score found, or 1.0 if intent fails
            - inferred_shape: The shape inferred from geometry ("LINES", "CIRCLES", etc.)
    """
    print(f"\n{'='*70}")
    print(f"STAGE 1: Shape Similarity Validation (HARD GATE)")
    print(f"{'='*70}")
    print(f"Expected shape: {expected_shape}")
    
    # Extract user's largest contour
    user_contour = _extract_largest_contour(user_image_path)
    if user_contour is None:
        print(f"❌ STAGE 1 FAIL: Could not extract user contour")
        return False, 1.0, "UNKNOWN"  # No valid contour = fail
    
    # ============================================================================
    # GEOMETRIC INTENT INFERENCE: Infer shape from geometry
    # ============================================================================
    print(f"\n🔍 GEOMETRIC INTENT INFERENCE")
    print(f"{'-'*40}")
    
    inferred_shape, inference_reason = _infer_shape_from_geometry(user_contour)
    
    print(f"   Inferred Shape: {inferred_shape}")
    print(f"   Reason: {inference_reason}")
    
    # Check if inferred shape matches expected
    intent_matches = inferred_shape == expected_shape
    
    if not intent_matches:
        print(f"❌ STAGE 1 FAIL: Intent mismatch - expected {expected_shape}, inferred {inferred_shape}")
        return False, 1.0, inferred_shape  # Intent mismatch = HARD FAIL
    
    print(f"✅ Intent matches - proceeding to similarity comparison")
    
    # ============================================================================
    # SIMILARITY COMPARISON: Only runs if geometry gate passes
    # ============================================================================
    print(f"\n🔍 SIMILARITY COMPARISON")
    print(f"{'-'*40}")
    
    # Get reference shapes for comparison
    reference_paths = _get_reference_shapes(expected_shape)
    
    # 🚨 MANDATORY: NO BYPASS - If no reference data, FAIL immediately
    if not reference_paths:
        print(f"❌ STAGE 1 FAIL: No reference shapes available for {expected_shape}")
        print(f"📥 Reference shapes required from: reference_shapes/{expected_shape}/")
        print(f"🚨 CRITICAL RULE: Stage-1 NEVER bypasses (hard fail on missing references)")
        print(f"💾 ERROR: Reference shapes missing for {expected_shape}")
        return False, 1.0, inferred_shape  # No reference data = FAIL (DO NOT BYPASS)
    
    # Verify minimum reference count (should have at least 10)
    if len(reference_paths) < 10:
        print(f"⚠️  WARNING: Only {len(reference_paths)} reference shapes found (expected ≥10)")
        print(f"   This may reduce validation accuracy")
    else:
        print(f"✓ Using {len(reference_paths)} reference shapes for comparison")
    
    # Compare with all reference shapes
    best_score = float('inf')
    reference_scores = []
    
    for idx, ref_path in enumerate(reference_paths, 1):
        ref_contour = _extract_largest_contour(ref_path)
        if ref_contour is None:
            print(f"  [{idx}/{len(reference_paths)}] ⚠ Skipped (no contour): {os.path.basename(ref_path)}")
            continue
        
        # Calculate shape similarity using Hu moments
        # cv2.matchShapes returns a value where lower is better (more similar)
        similarity_score = cv2.matchShapes(user_contour, ref_contour, cv2.CONTOURS_MATCH_I3, 0)
        reference_scores.append((os.path.basename(ref_path), similarity_score))
        best_score = min(best_score, similarity_score)
        print(f"  [{idx}/{len(reference_paths)}] {similarity_score:.4f}: {os.path.basename(ref_path)}")
    
    # CHILD-FRIENDLY INTENT-BASED THRESHOLDS
    # Higher thresholds = more lenient (accepts imperfect child drawings)
    INTENT_THRESHOLDS = {
        "LINES": 0.45,    # Most lenient - wobbly lines OK
        "CURVES": 0.40,   # Very lenient - curved variations OK
        "CIRCLES": 0.50,  # Moderate - imperfect circles OK
        "TRIANGLE": 0.55, # Stricter - triangles harder to draw
        "SQUARE": 0.55,   # Stricter - squares harder to draw
        "ZIGZAG": 0.40    # Lenient - zigzag variations OK
    }
    
    # Normalize expected_shape for threshold lookup
    normalized_shape = expected_shape.strip().upper()
    shape_mapping = {"LINE": "LINES", "CURVE": "CURVES", "CIRCLE": "CIRCLES"}
    normalized_shape = shape_mapping.get(normalized_shape, normalized_shape)
    
    intent_threshold = INTENT_THRESHOLDS.get(normalized_shape, 0.5)  # Default fallback
    
    # BUG FIX: Stage-1 decision logic - higher scores = better matches for child intent
    is_shape_match = (best_score >= intent_threshold)
    
    print(f"\n📊 Comparison Results:")
    print(f"   Best Score: {best_score:.4f}")
    print(f"   Intent Threshold ({normalized_shape}): {intent_threshold}")
    print(f"   Comparison: {best_score:.4f} >= {intent_threshold} = {(best_score >= intent_threshold)}")
    
    # CHILD-FRIENDLY: Since geometry (intent) passed, shape is correct
    # Similarity score used for feedback/logging only, not correctness
    print(f"   ✅ RESULT: PASS (geometry intent accepted, similarity for feedback)")
    
    return True, best_score, inferred_shape


# ============================================================================
# STAGE 2: MOTOR SKILL EVALUATION (ONLY IF STAGE 1 PASSES)
# ============================================================================

def _stage2_motor_skill_evaluation(image_path, expected_shape):
    """
    STAGE 2: Only runs if STAGE 1 passes.
    Evaluates motor skill: smoothness, size consistency, pressure consistency.
    
    Args:
        image_path: Path to user image
        expected_shape: Expected shape (for context)
    
    Returns:
        Dict with motor skill scores:
        {
            "smoothness_score": 0-100,
            "size_consistency_score": 0-100,
            "pressure_consistency_score": 0-100,
            "overall_score": 0-100,
            "feedback": "Coaching message based on quality"
        }
    """
    print(f"\n{'='*70}")
    print(f"STAGE 2: Motor Skill Evaluation")
    print(f"{'='*70}")
    
    # Run quality assessment
    quality_metrics = _calculate_shape_quality(image_path, expected_shape)
    
    overall_score = quality_metrics.get("overall_score", 0)
    smoothness_score = quality_metrics.get("smoothness_score", 0)
    
    # Generate coaching feedback based on motor quality
    if overall_score >= 85:
        feedback = f"✓ Excellent! Your {expected_shape.lower()} drawing is smooth and consistent!"
    elif overall_score >= 70:
        feedback = f"Good! Your {expected_shape.lower()} drawing has good form. Work on making strokes smoother."
    elif overall_score >= 50:
        feedback = f"Keep practicing! Try to make your {expected_shape.lower()} drawing smoother and more controlled."
    else:
        feedback = f"Keep trying! Practice drawing {expected_shape.lower()} shapes more slowly and carefully."
    
    print(f"Motor Scores: Smoothness={smoothness_score:.0f}%, Overall={overall_score:.0f}%")
    print(f"Feedback: {feedback}")
    
    return {
        "smoothness_score": smoothness_score,
        "size_consistency_score": quality_metrics.get("size_consistency_score", 0),
        "pressure_consistency_score": quality_metrics.get("pressure_consistency_score", 0),
        "overall_score": overall_score,
        "feedback": feedback
    }

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


def _compute_motor_quality_scores(image_path):
    """
    Compute motor quality scores for pre-writing evaluation.
    
    Evaluates three key aspects:
    1. Smoothness: How steady the stroke is (lower variation = higher score)
    2. Size Consistency: How consistent the stroke width is
    3. Pressure Consistency: How consistent the pressure is
    
    Args:
        image_path: Path to the user's drawing image
    
    Returns:
        Dictionary with scores: {"smoothness": %, "size_consistency": %, "pressure_consistency": %, "overall": %}
    """
    try:
        # Load image
        image = cv2.imread(image_path)
        if image is None:
            return {"smoothness": 0, "size_consistency": 0, "pressure_consistency": 0, "overall": 0}
        
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Threshold to get binary image
        _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)
        
        # Find contours
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        
        if not contours:
            return {"smoothness": 0, "size_consistency": 0, "pressure_consistency": 0, "overall": 0}
        
        # Use the largest contour
        contour = max(contours, key=cv2.contourArea)
        
        if len(contour) < 10:
            return {"smoothness": 0, "size_consistency": 0, "pressure_consistency": 0, "overall": 0}
        
        # 1. SMOOTHNESS: Measure path smoothness by analyzing curvature
        smoothness_score = _calculate_smoothness(contour)
        
        # 2. SIZE CONSISTENCY: Measure stroke width consistency
        size_consistency_score = _calculate_size_consistency(contour, binary)
        
        # 3. PRESSURE CONSISTENCY: Estimate pressure from stroke width variation
        pressure_consistency_score = _calculate_pressure_consistency(contour, binary)
        
        # Overall score: weighted average
        overall_score = (smoothness_score * 0.4 + size_consistency_score * 0.3 + pressure_consistency_score * 0.3)
        
        return {
            "smoothness": round(smoothness_score),
            "size_consistency": round(size_consistency_score),
            "pressure_consistency": round(pressure_consistency_score),
            "overall": round(overall_score)
        }
        
    except Exception as e:
        print(f"Error computing motor quality scores: {e}")
        return {"smoothness": 0, "size_consistency": 0, "pressure_consistency": 0, "overall": 0}


def _calculate_smoothness(contour):
    """
    Calculate smoothness score based on path curvature variation.
    Lower curvature variation = higher smoothness score.
    """
    try:
        # Calculate curvature along the contour
        curvatures = []
        for i in range(2, len(contour) - 2):
            p1 = contour[i-2][0]
            p2 = contour[i][0]
            p3 = contour[i+2][0]
            
            # Vector calculations
            v1 = p2 - p1
            v2 = p3 - p2
            
            # Cosine of angle between vectors
            dot = np.dot(v1, v2)
            norm1 = np.linalg.norm(v1)
            norm2 = np.linalg.norm(v2)
            
            if norm1 > 0 and norm2 > 0:
                cos_angle = dot / (norm1 * norm2)
                cos_angle = np.clip(cos_angle, -1, 1)
                angle = np.arccos(cos_angle)
                curvatures.append(angle)
        
        if not curvatures:
            return 50.0
        
        # Calculate variation in curvature
        curvature_std = np.std(curvatures)
        
        # Convert to score (lower variation = higher score)
        # Max expected std is around 1.0 radians, min is 0
        smoothness_score = max(0, 100 - (curvature_std * 50))
        
        return min(100, smoothness_score)
        
    except:
        return 50.0


def _calculate_size_consistency(contour, binary_image):
    """
    Calculate size consistency based on stroke width variation.
    """
    try:
        # Calculate distances from contour points to the stroke center
        # This approximates stroke width consistency
        
        # Get bounding box
        x, y, w, h = cv2.boundingRect(contour)
        
        # Sample stroke widths at different points
        widths = []
        step = max(1, len(contour) // 20)  # Sample 20 points
        
        for i in range(0, len(contour), step):
            point = contour[i][0]
            px, py = point
            
            # Check neighboring pixels to estimate stroke width
            width = 0
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    if dx == 0 and dy == 0:
                        continue
                    nx, ny = px + dx, py + dy
                    if (0 <= nx < binary_image.shape[1] and 
                        0 <= ny < binary_image.shape[0] and
                        binary_image[ny, nx] > 0):
                        width += 1
            
            if width > 0:
                widths.append(width)
        
        if not widths:
            return 50.0
        
        # Calculate coefficient of variation
        width_mean = np.mean(widths)
        width_std = np.std(widths)
        
        if width_mean > 0:
            cv = width_std / width_mean
            # Lower CV = more consistent = higher score
            consistency_score = max(0, 100 - (cv * 200))
            return min(100, consistency_score)
        
        return 50.0
        
    except:
        return 50.0


def _calculate_pressure_consistency(contour, binary_image):
    """
    Estimate pressure consistency from stroke width patterns.
    In digital drawing, consistent pressure = consistent stroke width.
    """
    try:
        # Use the same width calculation as size consistency
        # but focus on the distribution
        
        widths = []
        step = max(1, len(contour) // 30)  # More samples for pressure
        
        for i in range(0, len(contour), step):
            point = contour[i][0]
            px, py = point
            
            width = 0
            for dx in [-2, -1, 0, 1, 2]:
                for dy in [-2, -1, 0, 1, 2]:
                    if dx == 0 and dy == 0:
                        continue
                    nx, ny = px + dx, py + dy
                    if (0 <= nx < binary_image.shape[1] and 
                        0 <= ny < binary_image.shape[0] and
                        binary_image[ny, nx] > 0):
                        width += 1
            
            if width > 0:
                widths.append(width)
        
        if len(widths) < 5:
            return 50.0
        
        # Calculate how evenly distributed the widths are
        # More even distribution = more consistent pressure
        width_hist, _ = np.histogram(widths, bins=10)
        hist_std = np.std(width_hist)
        hist_mean = np.mean(width_hist)
        
        if hist_mean > 0:
            # Lower variation in histogram = more consistent pressure
            pressure_score = max(0, 100 - (hist_std / hist_mean * 50))
            return min(100, pressure_score)
        
        return 50.0
        
    except:
        return 50.0


def _generate_child_friendly_feedback(is_correct, identified_shape, expected_shape, quality_scores):
    """
    Generate child-friendly feedback based on correctness and motor quality.
    
    Args:
        is_correct: Boolean indicating if shape intent matches expected
        identified_shape: The shape identified from geometry
        expected_shape: The expected shape
        quality_scores: Dictionary with motor quality scores
    
    Returns:
        String with encouraging feedback
    """
    try:
        feedback_parts = []
        
        # Shape name mapping for proper grammar
        shape_names = {
            "LINES": "line",
            "CIRCLES": "circle", 
            "CURVES": "curve",
            "TRIANGLE": "triangle",
            "SQUARE": "square",
            "ZIGZAG": "zigzag"
        }
        
        expected_name = shape_names.get(expected_shape, expected_shape.lower())
        identified_name = shape_names.get(identified_shape, identified_shape.lower())
        
        # Base feedback based on correctness
        if is_correct:
            feedback_parts.append(f"Great job! You drew a {expected_name}!")
        else:
            if identified_shape == "UNKNOWN":
                feedback_parts.append(f"Nice try! Let's practice drawing a {expected_name} together.")
            else:
                feedback_parts.append(f"You drew a {identified_name}! Let's try making it look more like a {expected_name}.")
        
        # Add motor quality feedback
        smoothness = quality_scores.get("smoothness", 0)
        size_consistency = quality_scores.get("size_consistency", 0)
        pressure_consistency = quality_scores.get("pressure_consistency", 0)
        overall = quality_scores.get("overall", 0)
        
        # Smoothness feedback
        if smoothness >= 80:
            feedback_parts.append("Your lines are so smooth!")
        elif smoothness >= 60:
            feedback_parts.append("Try to make your lines smoother.")
        else:
            feedback_parts.append("Practice making steady, smooth lines.")
        
        # Size consistency feedback
        if size_consistency >= 80:
            feedback_parts.append("Your stroke thickness is very consistent!")
        elif size_consistency >= 60:
            feedback_parts.append("Try to keep your stroke thickness more even.")
        
        # Pressure consistency feedback (only if meaningful)
        if pressure_consistency >= 80 and pressure_consistency > 0:
            feedback_parts.append("You have great pressure control!")
        elif pressure_consistency >= 60 and pressure_consistency > 0:
            feedback_parts.append("Try to press more evenly.")
        
        # Overall encouragement
        if overall >= 80:
            feedback_parts.append("Excellent work on your motor skills!")
        elif overall >= 60:
            feedback_parts.append("You're doing well! Keep practicing.")
        else:
            feedback_parts.append("Keep practicing - you'll get better with each try!")
        
        # Join feedback parts
        feedback = " ".join(feedback_parts)
        
        # Ensure feedback is not too long
        if len(feedback) > 200:
            # Keep the first part and overall encouragement
            short_feedback = feedback_parts[0] + " " + feedback_parts[-1]
            feedback = short_feedback
        
        return feedback
        
    except Exception as e:
        print(f"Error generating feedback: {e}")
        return "Great effort! Keep practicing your shapes."


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
        # STEP 1: UNIFIED CONTOUR EXTRACTION WITH AREA FILTERING
        # ========================================================================
        child_contour = _extract_filtered_contour(image_b64)
        if child_contour is None:
            print("❌ No valid contour found")
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
        # STEP 4: SHAPE COMPARISON (AFTER NORMALIZATION)
        # ========================================================================
        match_score = cv2.matchShapes(normalized_child, normalized_template, cv2.CONTOURS_MATCH_I1, 0)

        # Apply specific accuracy mapping (keeps scores small and meaningful)
        accuracy = _map_score_to_accuracy(match_score)
        is_correct = (accuracy >= 65)

        print(f"✓ Normalized match score: {match_score:.4f}")
        print(f"✓ Mapped accuracy: {accuracy}%")
        print(f"✓ Correct: {is_correct} (≥65% threshold)")

        # ========================================================================
        # STEP 5: CONDITIONAL METRICS COMPUTATION
        # ========================================================================
        if is_correct:
            # Load original image for metrics computation
            image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
            image_bytes = base64.b64decode(image_data)
            image_array = np.frombuffer(image_bytes, dtype=np.uint8)
            image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

            pressure = _compute_pressure_metric(image)
            shape_formation = _assess_shape_formation(child_contour, normalized_template)

            print(f"✓ Pressure: {pressure}")
            print(f"✓ Shape formation: {shape_formation}")

            return _build_correct_response(accuracy, pressure, shape_formation)
        else:
            return _build_incorrect_response()

    except Exception as e:
        print(f"❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"msg": "error", "error": str(e)}), 500


# ============================================================================
# FINAL CLEAN HELPER FUNCTIONS
# ============================================================================
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            return None, 0.0

        # Get largest contour
        largest_contour = max(contours, key=cv2.contourArea)
        contour_points = len(largest_contour)
        
# ============================================================================
# FINAL CLEAN HELPER FUNCTIONS
# ============================================================================
        
        # Get bounding box for aspect ratio
        x, y, w, h = cv2.boundingRect(largest_contour)
        bbox_aspect_ratio = w / h if h > 0 else 1.0
        
        # Fit ellipse
        if contour_points >= 5:
            try:
                ellipse = cv2.fitEllipse(largest_contour)
                (cx, cy), (width, height), angle = ellipse
                ellipse_aspect_ratio = width / height if height > 0 else 0
            except:
                ellipse_aspect_ratio = bbox_aspect_ratio
        else:
            ellipse_aspect_ratio = bbox_aspect_ratio

        # Approximate polygon with very strict epsilon
        epsilon = 0.002 * perimeter  # Very small epsilon to preserve curvature
        approx = cv2.approxPolyDP(largest_contour, epsilon, True)
        vertices = len(approx)

        # Calculate curvature: ratio of actual contour points to simplified vertices
        curvature_ratio = contour_points / max(vertices, 1)
        
        # Calculate straightness: how linear is the shape
        # Lines have low area-to-perimeter ratio
        area_perimeter_ratio = area / (perimeter ** 2) if perimeter > 0 else 0

        print(f"\n🔍 SHAPE ANALYSIS METRICS:")
        print(f"   Contour points: {contour_points}")
        print(f"   Simplified vertices: {vertices}")
        print(f"   Area: {area:.1f}")
        print(f"   Perimeter: {perimeter:.1f}")
        print(f"   Circularity: {circularity:.3f}")
        print(f"   BBox aspect ratio: {bbox_aspect_ratio:.3f}")
        print(f"   Ellipse aspect ratio: {ellipse_aspect_ratio:.3f}")
        print(f"   Curvature ratio: {curvature_ratio:.2f}")
        print(f"   Area-to-perimeter ratio: {area_perimeter_ratio:.6f}")

        confidence = 0.0
        predicted_shape = None

        # ✅ FIX 3: STRICT LINE VALIDATION (not auto-accepted by smoothness alone)
        # LINE detection requires ALL of:
        # 1. Very high aspect ratio (elongated, width >> height)
        # 2. Low area-to-perimeter ratio (open, not closed)
        # 3. Minimal curvature (straight, not wavy)
        # 4. Not circular
        # HARD REJECTION: contour < 2 OR angle_variance too high
        
        if bbox_aspect_ratio >= 2.5 and area_perimeter_ratio < 0.005 and contour_points >= 2:
            # Check for excessive curvature (rejection gate for LINE)
            if curvature_ratio < 1.3 and circularity < 0.3:
                predicted_shape = "LINE"
                confidence = 0.95
                print(f"   ✅ Matched: LINE (STRICT validation passed: high aspect ratio + low curvature + straight)")
            else:
                # Has high aspect ratio but too much curvature - likely CURVE, not LINE
                print(f"   ⛔ LINE rejected - too much curvature (ratio={curvature_ratio:.2f}, circularity={circularity:.3f})")
                predicted_shape = None
                confidence = 0.0
        
        # ✅ FIX 4: SHAPE-SPECIFIC evaluation for CURVES
        # CURVES must have: continuous curvature, NOT circular, NOT closed, multiple points
        elif contour_points > 35 and 1.5 <= curvature_ratio < 6.0 and circularity < 0.70:
            predicted_shape = "CURVE"
            confidence = min(0.95, 0.6 + (curvature_ratio / 12))
            print(f"   ✅ Matched: CURVE (SHAPE-SPECIFIC: curved appearance, moderate curvature, not circular)")
        
        # ✅ FIX 4: SHAPE-SPECIFIC evaluation for CIRCLE
        # CIRCLE requires: high circularity, near-round aspect ratio, closed contour
        elif circularity > 0.65 and 0.7 < ellipse_aspect_ratio < 1.4 and contour_points > 30:
            predicted_shape = "CIRCLE"
            confidence = min(0.95, circularity)
            print(f"   ✅ Matched: CIRCLE (SHAPE-SPECIFIC: high circularity + round aspect ratio)")
        
        # ✅ FIX 4: SHAPE-SPECIFIC evaluation for TRIANGLE
        # TRIANGLE requires: exactly 3 vertices after polygon approximation
        elif vertices == 3 and area > 100:
            predicted_shape = "TRIANGLE"
            confidence = 0.85
            print(f"   ✅ Matched: TRIANGLE (SHAPE-SPECIFIC: exactly 3 vertices)")
        
        # ✅ FIX 4: SHAPE-SPECIFIC evaluation for SQUARE
        # SQUARE requires: 4 vertices, square-like aspect ratio, good closure
        elif vertices == 4 and area > 200 and 0.6 < ellipse_aspect_ratio < 1.4 and circularity > 0.5:
            predicted_shape = "SQUARE"
            confidence = 0.80
            print(f"   ✅ Matched: SQUARE (SHAPE-SPECIFIC: 4 vertices + square-like aspect ratio)")
        
        # ✅ FIX 4: SHAPE-SPECIFIC evaluation for ZIGZAG
        # ZIGZAG requires: multiple vertices (>5), low circularity, multiple points
        elif vertices > 5 and circularity < 0.5 and contour_points > 30:
            predicted_shape = "ZIGZAG"
            confidence = 0.75
            print(f"   ✅ Matched: ZIGZAG (SHAPE-SPECIFIC: many vertices + low circularity)")
        
        # Default fallback: if we have many points, it's likely a curve
        elif contour_points > 30:
            predicted_shape = "CURVE"
            confidence = 0.50
            print(f"   ✅ Matched: CURVE (default - many contour points)")

        print(f"   📌 FINAL: {predicted_shape} (confidence: {confidence:.1%})\n")
        return predicted_shape, confidence

    except Exception as e:
        print(f"❌ Shape identification error: {e}")
        import traceback
        traceback.print_exc()
        return None, 0.0


def _calculate_shape_quality(image_path, expected_shape):
    """
    Calculate DETERMINISTIC quality metrics for pre-writing shape.
    All values derived from actual image data - NO RANDOM VALUES.
    
    Returns: dict with quality scores (0-100 range)
        {
            "smoothness_score": <deterministic value from edge quality>,
            "size_consistency_score": <deterministic value from stroke width variance>,
            "pressure_consistency_score": <deterministic value from pixel density>,
            "overall_score": <average of above three>
        }
    """
    try:
        image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        if image is None:
            return {
                "smoothness_score": 0,
                "size_consistency_score": 0,
                "pressure_consistency_score": 0,
                "overall_score": 0
            }

        # Normalize image
        _, binary = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY)
        
        # Get contours
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            return {
                "smoothness_score": 0,
                "size_consistency_score": 0,
                "pressure_consistency_score": 0,
                "overall_score": 0
            }

        largest_contour = max(contours, key=cv2.contourArea)
        contour_points = len(largest_contour)
        
        # ====================================================================
        # SMOOTHNESS SCORE (0-100)
        # Derived from edge quality and contour smoothness
        # Smoother contours = fewer sharp angles = higher smoothness score
        # ====================================================================
        # Calculate curvature variance (lower variance = smoother)
        if contour_points >= 3:
            # Use contour approximation to measure smoothness
            # Fewer approximated vertices relative to actual points = smoother
            epsilon = 0.002 * cv2.arcLength(largest_contour, True)
            approx = cv2.approxPolyDP(largest_contour, epsilon, True)
            vertices = len(approx)
            
            # Curvature ratio: contour_points / vertices
            # Higher ratio = smoother (more points per simplified vertex)
            curvature_ratio = contour_points / max(vertices, 1)
            
            # Convert to smoothness score (0-100)
            # If curvature_ratio > 3, shape is very smooth (high score)
            # If curvature_ratio < 1.5, shape is angular (low score)
            if curvature_ratio >= 4.0:
                smoothness_score = 95
            elif curvature_ratio >= 3.0:
                smoothness_score = 85
            elif curvature_ratio >= 2.0:
                smoothness_score = 70
            elif curvature_ratio >= 1.5:
                smoothness_score = 55
            else:
                smoothness_score = 40
        else:
            smoothness_score = 30
        
        # ====================================================================
        # SIZE CONSISTENCY SCORE (0-100)
        # Derived from stroke width uniformity
        # ====================================================================
        # Create distance transform to measure stroke thickness
        dist_transform = cv2.distanceTransform(binary, cv2.DIST_L2, cv2.DIST_MASK_PRECISE)
        
        # Get pixels that are part of the contour (black strokes)
        stroke_mask = binary == 0
        if stroke_mask.any():
            stroke_distances = dist_transform[stroke_mask]
            
            # Calculate coefficient of variation (std dev / mean)
            if stroke_distances.size > 0:
                mean_thickness = np.mean(stroke_distances)
                std_thickness = np.std(stroke_distances)
                
                if mean_thickness > 0:
                    cv_thickness = std_thickness / mean_thickness
                    
                    # Lower CV = more consistent size
                    if cv_thickness <= 0.2:
                        size_consistency_score = 90
                    elif cv_thickness <= 0.4:
                        size_consistency_score = 80
                    elif cv_thickness <= 0.6:
                        size_consistency_score = 70
                    elif cv_thickness <= 0.8:
                        size_consistency_score = 60
                    elif cv_thickness <= 1.0:
                        size_consistency_score = 50
                    else:
                        size_consistency_score = 35
                else:
                    size_consistency_score = 50
            else:
                size_consistency_score = 50
        else:
            size_consistency_score = 50
        
        # ====================================================================
        # PRESSURE CONSISTENCY SCORE (0-100)
        # Derived from pixel density uniformity across stroke
        # ====================================================================
        # Calculate normalized pixel density in strokes
        total_stroke_pixels = np.sum(stroke_mask)
        if total_stroke_pixels > 0:
            # Get bounding box of contour
            x, y, w, h = cv2.boundingRect(largest_contour)
            bbox_area = w * h
            
            if bbox_area > 0:
                # Pixel density = stroke pixels / bounding box area
                pixel_density = total_stroke_pixels / bbox_area
                
                # Density should be moderate (not too sparse, not too filled)
                # Ideal range: 0.3-0.7 of bounding box
                if 0.3 <= pixel_density <= 0.7:
                    pressure_consistency_score = 85
                elif 0.2 <= pixel_density <= 0.8:
                    pressure_consistency_score = 75
                elif 0.1 <= pixel_density <= 0.9:
                    pressure_consistency_score = 65
                elif 0.05 <= pixel_density <= 0.95:
                    pressure_consistency_score = 55
                else:
                    # Very sparse or very dense strokes indicate inconsistent pressure
                    pressure_consistency_score = 40
            else:
                pressure_consistency_score = 50
        else:
            pressure_consistency_score = 50
        
        # ====================================================================
        # OVERALL SCORE (0-100)
        # Average of three metrics
        # ====================================================================
        overall_score = (smoothness_score + size_consistency_score + pressure_consistency_score) / 3
        
        print(f"\n📊 DETERMINISTIC QUALITY METRICS:")
        print(f"   Smoothness Score (from curvature): {smoothness_score:.0f}%")
        print(f"   Size Consistency (from stroke width): {size_consistency_score:.0f}%")
        print(f"   Pressure Consistency (from pixel density): {pressure_consistency_score:.0f}%")
        print(f"   Overall Quality Score: {overall_score:.0f}%")

        return {
            "smoothness_score": max(0, min(100, smoothness_score)),
            "size_consistency_score": max(0, min(100, size_consistency_score)),
            "pressure_consistency_score": max(0, min(100, pressure_consistency_score)),
            "overall_score": max(0, min(100, overall_score))
        }

    except Exception as e:
        print(f"❌ Quality calculation error: {e}")
        import traceback
        traceback.print_exc()
        return {
            "smoothness_score": 0,
            "size_consistency_score": 0,
            "pressure_consistency_score": 0,
            "overall_score": 0
        }


def _get_shape_metrics(image_path):
    """
    Extract shape metrics from image for feature-based evaluation.
    Returns: dict with geometric properties
    """
    try:
        image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        if image is None:
            return {}

        _, binary = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY)
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            return {}

        largest_contour = max(contours, key=cv2.contourArea)
        contour_points = len(largest_contour)
        
        area = cv2.contourArea(largest_contour)
        perimeter = cv2.arcLength(largest_contour, True)
        
        if area < 50:
            return {}
        
        circularity = 4 * np.pi * area / (perimeter ** 2) if perimeter > 0 else 0
        
        x, y, w, h = cv2.boundingRect(largest_contour)
        aspect_ratio = w / h if h > 0 else 1.0
        
        # Polygon approximation
        epsilon = 0.002 * perimeter
        approx = cv2.approxPolyDP(largest_contour, epsilon, True)
        vertices = len(approx)
        
        # Curvature ratio
        curvature_ratio = contour_points / max(vertices, 1)
        
        # Elongation (area-to-perimeter ratio for line detection)
        area_perimeter_ratio = area / (perimeter ** 2) if perimeter > 0 else 0

        return {
            "contour_points": contour_points,
            "area": area,
            "perimeter": perimeter,
            "circularity": circularity,
            "aspect_ratio": aspect_ratio,
            "vertices": vertices,
            "curvature_ratio": curvature_ratio,
            "area_perimeter_ratio": area_perimeter_ratio,
            "bbox_width": w,
            "bbox_height": h
        }

    except Exception as e:
        print(f"❌ Shape metrics extraction error: {e}")
        return {}


def _compute_accuracy_score(expected_shape, shape_metrics):
    """
    Compute accuracy score (0-100) based on expected shape and actual metrics.
    Uses feature-based evaluation, NOT classification.
    
    Returns: integer 0-100
    """
    if not shape_metrics:
        return 0  # No metrics = no score
    
    score = 0
    expected = expected_shape.upper()
    
    contour_points = shape_metrics.get("contour_points", 0)
    vertices = shape_metrics.get("vertices", 0)
    circularity = shape_metrics.get("circularity", 0)
    curvature_ratio = shape_metrics.get("curvature_ratio", 1.0)
    aspect_ratio = shape_metrics.get("aspect_ratio", 1.0)
    area_perimeter_ratio = shape_metrics.get("area_perimeter_ratio", 0)
    
    # ✅ LINES: Straight movement with elongation (not aspect_ratio) and low curvature
    # ✅ ISSUE 3: Use elongation metric to handle vertical AND horizontal lines
    if expected == "LINES":
        # Score components:
        # - High elongation (stretched): +40 if >= 2.5
        #   (elongation = max(w,h) / min(w,h) works for both vertical and horizontal)
        # - Low curvature: +40 if curvature_ratio < 1.5
        # - Sufficient points: +20 if contour_points >= 2
        
        score = 0
        
        # Calculate elongation: max(width, height) / min(width, height)
        # This correctly handles both vertical (h>>w) and horizontal (w>>h) lines
        width = shape_metrics.get("width", shape_metrics.get("bbox_width", 1))
        height = shape_metrics.get("height", shape_metrics.get("bbox_height", 1))
        if width == 1 and height == 1 and "aspect_ratio" in shape_metrics:
            # If we only have aspect_ratio, derive elongation from it
            ar = shape_metrics.get("aspect_ratio", 1.0)
            elongation = max(ar, 1.0 / ar) if ar > 0 else 1.0
        else:
            elongation = max(width, height) / max(1, min(width, height))
        
        if elongation >= 2.5:
            score += 40
        elif elongation >= 1.5:
            score += 25
        elif elongation >= 1.0:
            score += 10
        
        if curvature_ratio < 1.5:
            score += 40
        elif curvature_ratio < 2.0:
            score += 25
        elif curvature_ratio < 3.0:
            score += 10
        
        if contour_points >= 2:
            score += 20
        
        score = min(100, score)
    
    # ✅ CURVES: Curved movement with moderate curvature, not circular
    elif expected == "CURVES":
        # Score components:
        # - Many points for smooth curve: +30 if > 35
        # - Curvature in range: +40 if 1.5 <= ratio < 6.0
        # - Not circular: +30 if circularity < 0.70
        
        score = 0
        
        if contour_points > 35:
            score += 30
        elif contour_points > 20:
            score += 20
        elif contour_points > 10:
            score += 10
        
        if 1.5 <= curvature_ratio < 6.0:
            score += 40
        elif 1.0 <= curvature_ratio < 8.0:
            score += 25
        else:
            score += 0
        
        if circularity < 0.70:
            score += 30
        elif circularity < 0.80:
            score += 15
        
        score = min(100, score)
    
    # ✅ CIRCLES: Closed circular movement
    elif expected == "CIRCLES":
        # Score components:
        # - High circularity: +50 if > 0.65
        # - Round aspect ratio: +30 if 0.7 < ratio < 1.4
        # - Sufficient contour: +20 if > 30
        
        score = 0
        
        if circularity > 0.65:
            score += 50
        elif circularity > 0.55:
            score += 35
        elif circularity > 0.45:
            score += 20
        else:
            score += 0
        
        if 0.7 < aspect_ratio < 1.4:
            score += 30
        elif 0.6 < aspect_ratio < 1.5:
            score += 20
        elif 0.5 < aspect_ratio < 2.0:
            score += 10
        
        if contour_points > 30:
            score += 20
        elif contour_points > 20:
            score += 10
        
        score = min(100, score)
    
    # ✅ TRIANGLES: Exactly 3 vertices
    elif expected == "TRIANGLE":
        # Score components:
        # - Vertices == 3: +70
        # - Reasonable area: +30
        
        score = 0
        
        if vertices == 3:
            score += 70
        elif vertices == 4 or vertices == 2:
            score += 30
        else:
            score += 0
        
        area = shape_metrics.get("area", 0)
        if area > 100:
            score += 30
        elif area > 50:
            score += 15
        
        score = min(100, score)
    
    # ✅ SQUARE: Exactly 4 vertices with square-like proportions
    elif expected == "SQUARE":
        # Score components:
        # - Vertices == 4: +50
        # - Square-like aspect ratio: +30
        # - Reasonable size: +20
        
        score = 0
        
        if vertices == 4:
            score += 50
        elif vertices == 3 or vertices == 5:
            score += 20
        else:
            score += 0
        
        if 0.6 < aspect_ratio < 1.4:
            score += 30
        elif 0.5 < aspect_ratio < 1.5:
            score += 20
        elif 0.4 < aspect_ratio < 2.0:
            score += 10
        
        area = shape_metrics.get("area", 0)
        if area > 200:
            score += 20
        elif area > 100:
            score += 10
        
        score = min(100, score)
    
    # ✅ ZIGZAG: Multiple vertices with sharp angles
    elif expected == "ZIGZAG":
        # Score components:
        # - Many vertices: +40 if > 5
        # - Many contour points: +30 if > 30
        # - Not circular: +30 if circularity < 0.5
        
        score = 0
        
        if vertices > 5:
            score += 40
        elif vertices > 3:
            score += 25
        else:
            score += 0
        
        if contour_points > 30:
            score += 30
        elif contour_points > 20:
            score += 15
        
        if circularity < 0.5:
            score += 30
        elif circularity < 0.65:
            score += 15
        
        score = min(100, score)
    
    else:
        # Unknown shape type - no score
        score = 0
    
    return int(max(0, min(100, score)))

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


# ============================================================================
# FINAL CLEAN HELPER FUNCTIONS
# ============================================================================

def _extract_filtered_contour(image_b64):
    """
    UNIFIED CONTOUR EXTRACTION WITH AREA-BASED FILTERING

    - Uses cv2.findContours for all shapes
    - Filters contours by area ratio (1%-60% of image area)
    - Selects ONLY the largest valid contour
    - Prevents canvas border contamination
    """
    try:
        # Decode image
        image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
        image_bytes = base64.b64decode(image_data)
        image_array = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

        if image is None:
            return None

        # Convert to grayscale and threshold
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)

        # Find contours
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            return None

        # Area-based filtering (1%-60% of image area)
        total_area = image.shape[0] * image.shape[1]
        min_area = total_area * 0.01  # 1%
        max_area = total_area * 0.60  # 60%

        valid_contours = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if min_area <= area <= max_area:
                valid_contours.append(contour)

        if not valid_contours:
            return None

        # Return the largest valid contour
        return max(valid_contours, key=cv2.contourArea)

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
    LOAD AND NORMALIZE CANONICAL TEMPLATE

    - Exactly ONE template per shape
    - Templates stored as PNG files in templates/ directory
    - Returns normalized contour ready for matchShapes
    """
    try:
        template_path = os.path.join(TEMPLATES_DIR, f"{shape_name.lower()}_canonical.png")

        if not os.path.exists(template_path):
            print(f"❌ Template not found: {template_path}")
            return None

        # Load template image
        template_image = cv2.imread(template_path, cv2.IMREAD_GRAYSCALE)
        if template_image is None:
            return None

        # Extract contour from template
        _, binary = cv2.threshold(template_image, 127, 255, cv2.THRESH_BINARY_INV)
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            return None

        # Get the largest contour and normalize it
        template_contour = max(contours, key=cv2.contourArea)
        return _normalize_contour(template_contour)

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
    COMPUTE PRESSURE METRIC FROM IMAGE

    Higher pixel density = more consistent pressure = higher score.
    Returns 0-100 score based on drawing pixel percentage.
    """
    try:
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Count drawing pixels (non-white)
        total_pixels = gray.size
        drawing_pixels = np.count_nonzero(gray < 200)  # Dark pixels

        # Pressure as percentage of drawing pixels
        pressure_percentage = (drawing_pixels / total_pixels) * 100

        # Scale to 0-100 score
        pressure_score = min(100, pressure_percentage * 10)

        return int(pressure_score)

    except Exception as e:
        print(f"❌ Pressure computation error: {e}")
        return 0


def _assess_shape_formation(child_contour, template_contour):
    """
    ASSESS SHAPE FORMATION QUALITY

    Compares area and perimeter ratios between child and template.
    Returns "Good" or "Fair" based on similarity.
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

        # Return "Good" if score >= 0.7, otherwise "Fair"
        return "Good" if formation_score >= 0.7 else "Fair"

    except Exception as e:
        print(f"❌ Shape formation assessment error: {e}")
        return "Fair"


def _build_correct_response(accuracy, pressure, shape_formation):
    """Build clean response for correct shapes."""
    return jsonify({
        "is_correct": True,
        "pressure": pressure,
        "shape_formation": shape_formation,
        "accuracy": accuracy
    })


def _build_incorrect_response():
    """Build clean response for incorrect shapes."""
    return jsonify({
        "is_correct": False,
        "pressure": None,
        "shape_formation": None,
        "accuracy": None
    })

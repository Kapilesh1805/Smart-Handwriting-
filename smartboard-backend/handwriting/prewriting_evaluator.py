"""
PRE-WRITING MOTOR SKILLS EVALUATOR

Evaluates geometric shapes (line, curve, circle, square, zigzag) using OpenCV.
This is COMPLETELY ISOLATED from handwriting recognition (CLIP).

Pipeline:
1. Decode base64 image
2. OpenCV preprocessing (grayscale, threshold, morphology)
3. Contour extraction and analysis
4. Shape-specific geometry checks
5. Score 0-100 based on quality metrics
6. Return is_correct (score >= 70) with feedback

Shapes Evaluated:
- LINE: Single straight contour
- CURVE: Smooth curved contour
- CIRCLE: Closed oval/circular contour
- SQUARE: Closed 4-corner polygonal contour
- ZIGZAG: Open contour with sharp directional changes
"""

import base64
import io
import logging
import cv2
import numpy as np
from PIL import Image
from typing import Dict, Tuple, List
import math

logger = logging.getLogger(__name__)


# ============================================================================
# PREPROCESSING
# ============================================================================

def decode_base64_image(image_b64: str) -> Image.Image:
    """Decode base64 image to PIL Image (RGB)."""
    try:
        if "," in image_b64:
            _, encoded = image_b64.split(",", 1)
        else:
            encoded = image_b64
        img_bytes = base64.b64decode(encoded)
        return Image.open(io.BytesIO(img_bytes)).convert("RGB")
    except Exception as e:
        logger.error("[PREWRITING] Failed to decode base64: %s", e)
        raise


def preprocess_image_cv2(image_pil: Image.Image) -> np.ndarray:
    """
    Convert PIL image to OpenCV format for processing.
    
    Returns:
        grayscale image (H, W) ready for contour extraction
    """
    # Convert PIL to numpy (RGB)
    img_np = np.array(image_pil)
    
    # Convert RGB to grayscale
    gray = cv2.cvtColor(img_np, cv2.COLOR_RGB2GRAY)
    
    # Threshold to binary (white stroke on black or vice versa)
    # Use Otsu's method for automatic threshold
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)
    
    # Apply morphological operations to clean noise
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)
    binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel, iterations=1)
    
    logger.debug("[PREWRITING] Image preprocessed: shape=%s", binary.shape)
    return binary


def extract_contours(binary_image: np.ndarray) -> List[np.ndarray]:
    """
    Extract contours from binary image.
    
    Returns:
        List of contours (sorted by area, largest first)
    """
    contours, _ = cv2.findContours(binary_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Sort by area (largest first)
    contours = sorted(contours, key=cv2.contourArea, reverse=True)
    
    logger.debug("[PREWRITING] Extracted %d contours", len(contours))
    return contours


# ============================================================================
# GEOMETRY METRICS
# ============================================================================

def contour_area(contour: np.ndarray) -> float:
    """Compute contour area."""
    return cv2.contourArea(contour)


def contour_perimeter(contour: np.ndarray) -> float:
    """Compute contour perimeter."""
    return cv2.arcLength(contour, closed=True)


def contour_circularity(contour: np.ndarray) -> float:
    """
    Circularity = 4π * Area / Perimeter²
    Close to 1.0 = circle, close to 0 = line/elongated
    """
    area = cv2.contourArea(contour)
    perimeter = cv2.arcLength(contour, closed=True)
    
    if perimeter < 1e-6:
        return 0.0
    
    circularity = (4 * math.pi * area) / (perimeter ** 2)
    return min(circularity, 1.0)  # Cap at 1.0


def contour_closure(contour: np.ndarray) -> float:
    """
    Measure how closed the contour is (for circle/square detection).
    
    Returns:
        1.0 = perfectly closed, 0.0 = open
    """
    if len(contour) < 3:
        return 0.0
    
    # Compute first and last point distance
    start_point = contour[0][0]
    end_point = contour[-1][0]
    distance = np.linalg.norm(start_point - end_point)
    
    # Normalize by perimeter
    perimeter = cv2.arcLength(contour, closed=False)
    if perimeter < 1e-6:
        return 0.0
    
    closure = 1.0 - min(distance / (perimeter * 0.1), 1.0)
    return max(closure, 0.0)


def contour_straightness(contour: np.ndarray) -> float:
    """
    Measure straightness of a contour (for line detection).
    
    Returns:
        1.0 = perfectly straight, 0.0 = very curved
    
    Method: Compare actual contour length to direct endpoint distance.
    """
    if len(contour) < 3:
        return 0.0
    
    # Direct distance from start to end
    start = contour[0][0]
    end = contour[-1][0]
    direct_dist = np.linalg.norm(end - start)
    
    # Actual contour length
    contour_length = cv2.arcLength(contour, closed=False)
    
    if contour_length < 1e-6:
        return 0.0
    
    # Straightness: direct_dist / contour_length (closer to 1 = straighter)
    straightness = direct_dist / contour_length
    return min(straightness, 1.0)


def contour_curvature_uniformity(contour: np.ndarray, num_samples: int = 20) -> float:
    """
    Measure uniformity of curvature (for smooth curve detection).
    
    Returns:
        1.0 = uniform curvature, 0.0 = highly variable
    """
    if len(contour) < num_samples * 2:
        return 0.5
    
    # Sample points along contour
    step = len(contour) // num_samples
    curvatures = []
    
    for i in range(1, len(contour) - 1, step):
        p1 = contour[i - 1][0]
        p2 = contour[i][0]
        p3 = contour[i + 1][0]
        
        # Compute angle at p2
        v1 = p1 - p2
        v2 = p3 - p2
        
        norm1 = np.linalg.norm(v1)
        norm2 = np.linalg.norm(v2)
        
        if norm1 < 1e-6 or norm2 < 1e-6:
            continue
        
        cos_angle = np.dot(v1, v2) / (norm1 * norm2)
        cos_angle = np.clip(cos_angle, -1.0, 1.0)
        angle = math.acos(cos_angle)
        curvatures.append(angle)
    
    if not curvatures:
        return 0.5
    
    # Uniformity: 1 - (std / mean)
    curvatures = np.array(curvatures)
    mean_curv = np.mean(curvatures)
    std_curv = np.std(curvatures)
    
    if mean_curv < 1e-6:
        return 0.5
    
    uniformity = 1.0 - min(std_curv / mean_curv, 1.0)
    return max(uniformity, 0.0)


def approximate_polygon(contour: np.ndarray, epsilon_ratio: float = 0.02) -> np.ndarray:
    """
    Approximate contour as polygon using Ramer-Douglas-Peucker.
    
    Args:
        contour: Input contour
        epsilon_ratio: Approximation accuracy (relative to perimeter)
    
    Returns:
        Approximated polygon vertices
    """
    perimeter = cv2.arcLength(contour, closed=True)
    epsilon = epsilon_ratio * perimeter
    approx = cv2.approxPolyDP(contour, epsilon, closed=True)
    return approx


def count_corners(contour: np.ndarray, angle_threshold: float = 15.0) -> int:
    """
    Count corners (sharp direction changes) in contour.
    
    Args:
        contour: Input contour
        angle_threshold: Minimum angle change in degrees
    
    Returns:
        Number of corners detected
    """
    if len(contour) < 3:
        return 0
    
    corners = 0
    threshold_rad = math.radians(angle_threshold)
    
    for i in range(len(contour)):
        p1 = contour[(i - 1) % len(contour)][0]
        p2 = contour[i][0]
        p3 = contour[(i + 1) % len(contour)][0]
        
        v1 = p1 - p2
        v2 = p3 - p2
        
        norm1 = np.linalg.norm(v1)
        norm2 = np.linalg.norm(v2)
        
        if norm1 < 1e-6 or norm2 < 1e-6:
            continue
        
        cos_angle = np.dot(v1, v2) / (norm1 * norm2)
        cos_angle = np.clip(cos_angle, -1.0, 1.0)
        angle = math.acos(cos_angle)
        
        # Corner if angle < threshold (sharp turn)
        if angle < threshold_rad:
            corners += 1
    
    return corners


def polygon_angle_variance(polygon: np.ndarray) -> float:
    """
    Measure variance of interior angles in polygon.
    
    Returns:
        0.0 = uniform angles, high value = variable angles
    """
    if len(polygon) < 3:
        return 0.0
    
    angles = []
    for i in range(len(polygon)):
        p1 = polygon[(i - 1) % len(polygon)][0]
        p2 = polygon[i][0]
        p3 = polygon[(i + 1) % len(polygon)][0]
        
        v1 = p1 - p2
        v2 = p3 - p2
        
        norm1 = np.linalg.norm(v1)
        norm2 = np.linalg.norm(v2)
        
        if norm1 < 1e-6 or norm2 < 1e-6:
            continue
        
        cos_angle = np.dot(v1, v2) / (norm1 * norm2)
        cos_angle = np.clip(cos_angle, -1.0, 1.0)
        angle_rad = math.acos(cos_angle)
        angles.append(math.degrees(angle_rad))
    
    if not angles:
        return 0.0
    
    angles = np.array(angles)
    variance = np.var(angles)
    return variance


def side_length_uniformity(polygon: np.ndarray) -> float:
    """
    Measure uniformity of side lengths (for square detection).
    
    Returns:
        1.0 = uniform sides, 0.0 = variable sides
    """
    if len(polygon) < 3:
        return 0.0
    
    side_lengths = []
    for i in range(len(polygon)):
        p1 = polygon[i][0]
        p2 = polygon[(i + 1) % len(polygon)][0]
        length = np.linalg.norm(p2 - p1)
        side_lengths.append(length)
    
    side_lengths = np.array(side_lengths)
    mean_length = np.mean(side_lengths)
    
    if mean_length < 1e-6:
        return 0.0
    
    # Standard deviation relative to mean
    std_length = np.std(side_lengths)
    uniformity = 1.0 - min(std_length / mean_length, 1.0)
    return max(uniformity, 0.0)


# ============================================================================
# SHAPE EVALUATORS
# ============================================================================

def evaluate_line(contours: List[np.ndarray]) -> Tuple[float, str]:
    """
    Evaluate if contour is a good LINE.
    
    Criteria:
    - Single dominant contour
    - High straightness (>0.8)
    - Low curvature (circularity <0.3)
    - Long length
    
    Returns:
        (score 0-100, feedback)
    """
    if not contours:
        return 0.0, "No drawing detected. Please draw a line."
    
    main_contour = contours[0]
    area = contour_area(main_contour)
    
    # Must have reasonable size
    if area < 100:
        return 20.0, "Line is too small. Draw a longer line."
    
    straightness = contour_straightness(main_contour)
    circularity = contour_circularity(main_contour)
    
    logger.debug("[PREWRITING_LINE] straightness=%.3f, circularity=%.3f", straightness, circularity)
    
    # Scoring
    score = 0.0
    
    # Straightness component (0-50)
    if straightness > 0.85:
        score += 50
    elif straightness > 0.75:
        score += 40
    elif straightness > 0.65:
        score += 30
    elif straightness > 0.55:
        score += 20
    else:
        score += 10
    
    # Low curvature component (0-50)
    if circularity < 0.2:
        score += 50
    elif circularity < 0.3:
        score += 40
    elif circularity < 0.4:
        score += 30
    elif circularity < 0.5:
        score += 20
    else:
        score += 10
    
    score = score / 2.0  # Average of two components
    
    # Feedback
    if score >= 85:
        feedback = "Great line! Very straight! 📏"
    elif score >= 70:
        feedback = "Good line! Try to make it a bit straighter 🙂"
    elif score >= 50:
        feedback = "Nice try! Make your line straighter and smoother ✏️"
    else:
        feedback = "Keep practicing! Draw a long, straight line 📝"
    
    return score, feedback


def evaluate_curve(contours: List[np.ndarray]) -> Tuple[float, str]:
    """
    Evaluate if contour is a good CURVE.
    
    Criteria:
    - Single smooth contour
    - Moderate curvature (circularity 0.3-0.6)
    - Uniform curvature
    - Open (not closed)
    - Reasonable length
    
    Returns:
        (score 0-100, feedback)
    """
    if not contours:
        return 0.0, "No drawing detected. Please draw a curve."
    
    main_contour = contours[0]
    area = contour_area(main_contour)
    
    # Must have reasonable size
    if area < 100:
        return 20.0, "Curve is too small. Draw a longer curve."
    
    circularity = contour_circularity(main_contour)
    uniformity = contour_curvature_uniformity(main_contour)
    closure = contour_closure(main_contour)
    
    logger.debug("[PREWRITING_CURVE] circularity=%.3f, uniformity=%.3f, closure=%.3f",
                 circularity, uniformity, closure)
    
    # Scoring
    score = 0.0
    
    # Circularity component (0-40) - should be moderate, not too straight, not too circular
    if 0.3 <= circularity <= 0.6:
        score += 40
    elif 0.25 <= circularity <= 0.7:
        score += 30
    elif 0.2 <= circularity <= 0.8:
        score += 20
    else:
        score += 10
    
    # Uniformity component (0-35)
    if uniformity > 0.8:
        score += 35
    elif uniformity > 0.7:
        score += 28
    elif uniformity > 0.6:
        score += 21
    elif uniformity > 0.5:
        score += 14
    else:
        score += 7
    
    # Open contour component (0-25) - should be relatively open
    if closure < 0.3:
        score += 25
    elif closure < 0.5:
        score += 18
    elif closure < 0.7:
        score += 10
    else:
        score += 5
    
    # Normalize to 0-100
    score = (score / 100.0) * 100.0
    
    # Feedback
    if score >= 85:
        feedback = "Excellent curve! So smooth! ➰"
    elif score >= 70:
        feedback = "Nice curve! Try to make it smoother 🎨"
    elif score >= 50:
        feedback = "Good try! Make your curve more gradual and smooth 〰️"
    else:
        feedback = "Keep practicing curves! Draw smoothly and gradually 🌊"
    
    return score, feedback


def evaluate_circle(contours: List[np.ndarray]) -> Tuple[float, str]:
    """
    Evaluate if contour is a good CIRCLE.
    
    Criteria:
    - Single closed contour
    - High circularity (>0.75)
    - Minimal corners
    - Uniform radius
    - Reasonable size
    
    Returns:
        (score 0-100, feedback)
    """
    if not contours:
        return 0.0, "No drawing detected. Please draw a circle."
    
    main_contour = contours[0]
    area = contour_area(main_contour)
    
    # Must have reasonable size
    if area < 200:
        return 20.0, "Circle is too small. Draw a bigger circle."
    
    circularity = contour_circularity(main_contour)
    closure = contour_closure(main_contour)
    corners = count_corners(main_contour, angle_threshold=20.0)
    
    logger.debug("[PREWRITING_CIRCLE] circularity=%.3f, closure=%.3f, corners=%d",
                 circularity, closure, corners)
    
    # Scoring
    score = 0.0
    
    # Circularity component (0-40) - should be high
    if circularity > 0.80:
        score += 40
    elif circularity > 0.70:
        score += 32
    elif circularity > 0.60:
        score += 24
    elif circularity > 0.50:
        score += 16
    else:
        score += 8
    
    # Closure component (0-35) - must be closed
    if closure > 0.85:
        score += 35
    elif closure > 0.75:
        score += 28
    elif closure > 0.65:
        score += 21
    elif closure > 0.50:
        score += 14
    else:
        score += 5
    
    # Minimal corners component (0-25) - should have no corners
    if corners <= 4:
        score += 25
    elif corners <= 6:
        score += 18
    elif corners <= 8:
        score += 10
    else:
        score += 5
    
    # Normalize to 0-100
    score = (score / 100.0) * 100.0
    
    # Feedback
    if score >= 85:
        feedback = "Perfect circle! Great job! ⭕"
    elif score >= 70:
        feedback = "Nice circle! Try to make it rounder 🟡"
    elif score >= 50:
        feedback = "Good try! Close it up and make it more round 🔴"
    else:
        feedback = "Keep practicing! Draw a smooth, round circle ⚪"
    
    return score, feedback


def evaluate_square(contours: List[np.ndarray]) -> Tuple[float, str]:
    """
    Evaluate if contour is a good SQUARE.
    
    Criteria:
    - Single closed contour
    - Approximates to 4-sided polygon
    - Angles close to 90 degrees
    - Uniform side lengths
    - Minimal extra corners
    
    Returns:
        (score 0-100, feedback)
    """
    if not contours:
        return 0.0, "No drawing detected. Please draw a square."
    
    main_contour = contours[0]
    area = contour_area(main_contour)
    
    # Must have reasonable size
    if area < 200:
        return 20.0, "Square is too small. Draw a bigger square."
    
    # Approximate to polygon
    polygon = approximate_polygon(main_contour, epsilon_ratio=0.03)
    num_corners = len(polygon)
    
    closure = contour_closure(main_contour)
    angle_variance = polygon_angle_variance(polygon)
    side_uniformity = side_length_uniformity(polygon)
    
    logger.debug("[PREWRITING_SQUARE] corners=%d, closure=%.3f, angle_var=%.3f, side_uni=%.3f",
                 num_corners, closure, angle_variance, side_uniformity)
    
    # Scoring
    score = 0.0
    
    # Corner count component (0-40) - should have exactly 4
    if num_corners == 4:
        score += 40
    elif num_corners == 3:
        score += 20  # Triangle
    elif num_corners == 5:
        score += 30  # Close
    elif 3 <= num_corners <= 6:
        score += 20
    else:
        score += 5
    
    # Closure component (0-30) - must be closed
    if closure > 0.85:
        score += 30
    elif closure > 0.75:
        score += 24
    elif closure > 0.60:
        score += 18
    elif closure > 0.40:
        score += 10
    else:
        score += 5
    
    # Right angle consistency component (0-30)
    # Ideally angles should be ~90 degrees (variance low)
    if angle_variance < 5.0:
        score += 30
    elif angle_variance < 10.0:
        score += 24
    elif angle_variance < 15.0:
        score += 18
    elif angle_variance < 25.0:
        score += 10
    else:
        score += 5
    
    # Normalize to 0-100
    score = (score / 100.0) * 100.0
    
    # Feedback
    if score >= 85:
        feedback = "Excellent square! Perfect corners! ▢"
    elif score >= 70:
        feedback = "Nice square! Try to keep corners more even 🔲"
    elif score >= 50:
        feedback = "Good try! Make your corners sharper and more square 📦"
    else:
        feedback = "Keep practicing! Draw four straight sides with right angles ⬜"
    
    return score, feedback


def evaluate_zigzag(contours: List[np.ndarray]) -> Tuple[float, str]:
    """
    Evaluate if contour is a good ZIGZAG.
    
    Criteria:
    - Open contour with multiple sharp turns
    - At least 3 corners
    - Alternating direction changes
    - Not too smooth
    
    Returns:
        (score 0-100, feedback)
    """
    if not contours:
        return 0.0, "No drawing detected. Please draw a zigzag."
    
    main_contour = contours[0]
    area = contour_area(main_contour)
    
    # Must have reasonable size
    if area < 100:
        return 20.0, "Zigzag is too small. Draw a longer zigzag."
    
    corners = count_corners(main_contour, angle_threshold=25.0)
    closure = contour_closure(main_contour)
    straightness = contour_straightness(main_contour)
    
    logger.debug("[PREWRITING_ZIGZAG] corners=%d, closure=%.3f, straightness=%.3f",
                 corners, closure, straightness)
    
    # Scoring
    score = 0.0
    
    # Corner count component (0-40) - should have multiple corners
    if corners >= 5:
        score += 40
    elif corners >= 4:
        score += 32
    elif corners >= 3:
        score += 24
    elif corners >= 2:
        score += 16
    else:
        score += 5
    
    # Open contour component (0-35) - should be open
    if closure < 0.3:
        score += 35
    elif closure < 0.5:
        score += 28
    elif closure < 0.7:
        score += 14
    else:
        score += 5
    
    # Not-too-smooth component (0-25) - should have sharp turns
    # Opposite of straightness - we want low straightness
    if straightness < 0.5:
        score += 25
    elif straightness < 0.6:
        score += 20
    elif straightness < 0.7:
        score += 15
    elif straightness < 0.8:
        score += 10
    else:
        score += 5
    
    # Normalize to 0-100
    score = (score / 100.0) * 100.0
    
    # Feedback
    if score >= 85:
        feedback = "Perfect zigzag! Sharp turns! ⚡"
    elif score >= 70:
        feedback = "Nice zigzag! Try sharper turns 🔀"
    elif score >= 50:
        feedback = "Good try! Make more sharp direction changes 〰️"
    else:
        feedback = "Keep practicing! Draw sharp zigzag patterns ↗️↙️"
    
    return score, feedback


# ============================================================================
# MAIN EVALUATOR
# ============================================================================

def evaluate_prewriting_shape(image_b64: str, expected_shape: str) -> Dict:
    """
    Evaluate pre-writing shape quality using OpenCV geometry analysis.
    
    Args:
        image_b64: Base64-encoded canvas image
        expected_shape: Shape name (line, curve, circle, square, zigzag)
    
    Returns:
        {
            "is_correct": bool,  # True if score >= 70
            "score": float,      # 0-100
            "feedback": str
        }
    """
    
    expected_shape = expected_shape.strip().lower()
    logger.info("[PREWRITING] Evaluating shape: %s", expected_shape)
    
    # Validate shape
    valid_shapes = {"line", "curve", "circle", "square", "zigzag"}
    if expected_shape not in valid_shapes:
        logger.error("[PREWRITING] Invalid shape: %s", expected_shape)
        return {
            "is_correct": False,
            "score": 0.0,
            "feedback": f"Invalid shape. Supported: {', '.join(valid_shapes)}"
        }
    
    try:
        # Decode and preprocess
        image_pil = decode_base64_image(image_b64)
        binary_image = preprocess_image_cv2(image_pil)
        contours = extract_contours(binary_image)
        
        if not contours:
            logger.warning("[PREWRITING] No contours detected")
            return {
                "is_correct": False,
                "score": 0.0,
                "feedback": "No drawing detected. Please draw a " + expected_shape + "."
            }
        
        # Shape-specific evaluation
        if expected_shape == "line":
            score, feedback = evaluate_line(contours)
        elif expected_shape == "curve":
            score, feedback = evaluate_curve(contours)
        elif expected_shape == "circle":
            score, feedback = evaluate_circle(contours)
        elif expected_shape == "square":
            score, feedback = evaluate_square(contours)
        elif expected_shape == "zigzag":
            score, feedback = evaluate_zigzag(contours)
        else:
            score, feedback = 0.0, "Unknown shape"
        
        # Determine correctness (score >= 70)
        is_correct = score >= 70.0
        
        logger.info("[PREWRITING] Result: shape=%s, score=%.1f, is_correct=%s",
                   expected_shape, score, is_correct)
        
        return {
            "is_correct": is_correct,
            "score": round(score, 1),
            "feedback": feedback
        }
    
    except Exception as e:
        logger.error("[PREWRITING] Evaluation failed: %s", e)
        import traceback
        traceback.print_exc()
        return {
            "is_correct": False,
            "score": 0.0,
            "feedback": "Error evaluating shape. Please try again."
        }

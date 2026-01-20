from PIL import Image
import io
import cv2
import numpy as np
from typing import Tuple, Dict

CONFUSING_LETTERS = set(list("INSUVWX"))


def image_from_b64(image_b64: str) -> Image.Image:
    import base64
    data = base64.b64decode(image_b64)
    return Image.open(io.BytesIO(data)).convert("RGB")


def restrict_candidates_for(letter: str):
    """Return a restricted candidate set if expected letter is confusing."""
    if not letter:
        return None
    L = letter.strip().upper()
    if L in CONFUSING_LETTERS:
        return sorted(list(CONFUSING_LETTERS))
    return None


def extract_geometry(gray_image: np.ndarray) -> Dict[str, float]:
    """
    Extract shape features from a binary handwritten character.
    
    Args:
        gray_image: Grayscale image (0-255) or BGR image
        
    Returns:
        Dictionary of geometry metrics
    """
    # Convert to grayscale if needed
    if len(gray_image.shape) == 3:
        img_gray = cv2.cvtColor(gray_image, cv2.COLOR_BGR2GRAY)
    else:
        img_gray = gray_image
    
    # Threshold to binary
    _, binary = cv2.threshold(img_gray, 127, 255, cv2.THRESH_BINARY_INV)
    
    # Find contours (requires CV_8UC1 grayscale image)
    contours, _ = cv2.findContours(binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    
    if not contours:
        return {
            "has_loop": False,
            "is_vertical": False,
            "is_horizontal": False,
            "has_diagonal": False,
            "crossing_count": 0,
            "curvature": 0.0,
            "aspect_ratio": 0.0,
        }
    
    # Largest contour (main stroke)
    main_contour = max(contours, key=cv2.contourArea)
    
    # Fit to get principal axis
    moments = cv2.moments(main_contour)
    if moments["m00"] == 0:
        moments["m00"] = 1
    
    cx = int(moments["m10"] / moments["m00"])
    cy = int(moments["m01"] / moments["m00"])
    
    # Get bounding box
    x, y, w, h = cv2.boundingRect(main_contour)
    aspect_ratio = float(h) / float(w) if w > 0 else 0.0
    
    # Check for loops (holes in the character)
    has_loop = len(contours) > 1
    
    # Analyze stroke direction (principal component analysis)
    is_vertical = aspect_ratio > 2.0
    is_horizontal = aspect_ratio < 0.5
    
    # Check for diagonals (approximate)
    has_diagonal = not is_vertical and not is_horizontal and aspect_ratio > 0.8
    
    # Crossing detection: count horizontal line crossings (for X)
    crossing_count = count_crossings(binary)
    
    # Curvature estimation
    curvature = estimate_curvature(main_contour)
    
    return {
        "has_loop": has_loop,
        "is_vertical": is_vertical,
        "is_horizontal": is_horizontal,
        "has_diagonal": has_diagonal,
        "crossing_count": crossing_count,
        "curvature": curvature,
        "aspect_ratio": aspect_ratio,
    }


def count_crossings(binary: np.ndarray) -> int:
    """
    Rough crossing count (for X-like characters).
    Count central horizontal lines.
    """
    h, w = binary.shape
    mid_y = h // 2
    
    # Scan horizontal line through middle
    line = binary[mid_y, :]
    crossings = 0
    in_line = False
    
    for pixel in line:
        if pixel > 0:
            if not in_line:
                crossings += 1
            in_line = True
        else:
            in_line = False
    
    return crossings


def estimate_curvature(contour: np.ndarray) -> float:
    """
    Estimate curvature using polygon approximation.
    Returns fraction of curved segments.
    """
    if len(contour) < 5:
        return 0.0
    
    # Approximate contour with fewer points
    epsilon = 0.02 * cv2.arcLength(contour, True)
    approx = cv2.approxPolyDP(contour, epsilon, True)
    
    # More vertices = more curved
    return min(1.0, float(len(approx)) / 10.0)


def validate_confusing_letter(
    geometry: Dict[str, float],
    expected_letter: str
) -> Tuple[bool, float]:
    """
    Validate geometry against expected confusing letter.
    
    Args:
        geometry: Geometry features
        expected_letter: One of {I, N, S, U, V, W, X}
        
    Returns:
        (is_valid, confidence_boost) where confidence_boost is 0.0-0.2
    """
    expected = expected_letter.upper()
    
    # Base penalty (geometry doesn't match)
    penalty = 0.0
    boost = 0.0
    
    if expected == "I":
        # I: straight vertical, no loop, simple
        if geometry["is_vertical"] and not geometry["has_loop"]:
            boost = 0.15
        else:
            penalty = 0.25
    
    elif expected == "N":
        # N: diagonal + vertical, two strokes
        if geometry["has_diagonal"] and geometry["aspect_ratio"] > 0.8:
            boost = 0.15
        else:
            penalty = 0.20
    
    elif expected == "S":
        # S: curves, no straight vertical/horizontal
        if geometry["curvature"] > 0.3 and not (geometry["is_vertical"] or geometry["is_horizontal"]):
            boost = 0.15
        else:
            penalty = 0.20
    
    elif expected in ["U", "V", "W"]:
        # U/V/W: bottom curvature or vertex
        if geometry["aspect_ratio"] > 0.9 and geometry["curvature"] > 0.1:
            boost = 0.12
        else:
            penalty = 0.15
    
    elif expected == "X":
        # X: crossing diagonals
        if geometry["crossing_count"] >= 2 and geometry["has_diagonal"]:
            boost = 0.15
        else:
            penalty = 0.20
    
    return penalty > 0, boost

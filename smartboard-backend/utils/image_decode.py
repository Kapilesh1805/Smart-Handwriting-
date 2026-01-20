"""
Safe Base64 image decoder for Flutter canvas images.
Handles data URL prefixes, padding, URL-safe characters, and validation.
"""

import base64
import numpy as np
import cv2
import re


def decode_base64_image(image_b64: str):
    """
    Decode base64 image string to OpenCV format (BGR, uint8).
    
    Handles:
    - Data URL prefixes (data:image/png;base64,...)
    - Whitespace and newlines
    - URL-safe base64 variants (- instead of +, _ instead of /)
    - Missing padding (= characters)
    - Validation of output image
    
    Args:
        image_b64: Base64 encoded image string (with or without data URL prefix)
        
    Returns:
        np.ndarray: OpenCV BGR image (H, W, 3)
        
    Raises:
        ValueError: If any step fails (empty string, decode error, invalid output)
    """
    if not image_b64:
        raise ValueError("Empty image string")

    # Step 1: Remove data URL header if present
    if ',' in image_b64:
        image_b64 = image_b64.split(',')[-1]

    # Step 2: Remove all whitespace and newlines
    image_b64 = re.sub(r'\s+', '', image_b64)

    # Step 3: Fix URL-safe base64 encoding (- and _ instead of + and /)
    image_b64 = image_b64.replace('-', '+').replace('_', '/')

    # Step 4: Fix missing padding
    pad = len(image_b64) % 4
    if pad:
        image_b64 += '=' * (4 - pad)

    # Step 5: Decode base64 to bytes
    try:
        img_bytes = base64.b64decode(image_b64, validate=False)
    except Exception as e:
        raise ValueError(f"Base64 decode failed: {e}")

    # Step 6: Convert bytes to NumPy array
    img_np = np.frombuffer(img_bytes, np.uint8)

    # Step 7: Decode image using OpenCV
    img = cv2.imdecode(img_np, cv2.IMREAD_COLOR)

    # Step 8: Validate output
    if img is None:
        raise ValueError("OpenCV decode failed - invalid image data")

    if img.ndim != 3 or img.shape[2] != 3:
        raise ValueError(f"Invalid image shape: {img.shape}, expected (H, W, 3)")

    return img

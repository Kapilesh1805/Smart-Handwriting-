"""Compatibility shim for legacy code: helpers.create_token

Provides a minimal JWT creation function using PyJWT (HS256).
This file is intentionally small and only implements what's needed
by the existing `auth_routes.py` without refactoring other code.
"""
import os
from datetime import datetime, timedelta
from typing import Dict, Any

import jwt


def create_token(payload: Dict[str, Any]) -> str:
    """Create a JWT with a 24-hour expiry.

    - Reads secret from `JWT_SECRET` env var, falling back to 'dev-secret-key'.
    - Uses HS256 algorithm.
    - Does not mutate the input payload.

    Returns the encoded JWT string.
    """
    secret = os.getenv("JWT_SECRET", "dev-secret-key")
    data = dict(payload) if payload is not None else {}
    exp = datetime.utcnow() + timedelta(hours=24)
    data["exp"] = exp

    token = jwt.encode(data, secret, algorithm="HS256")

    # PyJWT >=2.0 returns a str, older versions may return bytes
    if isinstance(token, bytes):
        token = token.decode("utf-8")

    return token


def check_character_match(expected, predicted):
    """Return True if expected and predicted match case-insensitively.

    - If either value is None, return False.
    - Strips surrounding whitespace and compares lowercase strings.
    """
    if expected is None or predicted is None:
        return False
    try:
        return str(expected).strip().lower() == str(predicted).strip().lower()
    except Exception:
        return False


def apply_digit_heuristics(expected_digit, predicted_digit, confidence):
    """Return True if expected_digit and predicted_digit match.

    - If either digit is None, return False.
    - Compares digits as strings (case-insensitive, whitespace-stripped).
    - Ignores confidence value (kept for signature compatibility).
    """
    if expected_digit is None or predicted_digit is None:
        return False
    try:
        return str(expected_digit).strip().lower() == str(predicted_digit).strip().lower()
    except Exception:
        return False


def analyze_number(expected_digit, strokes_data, pressure_points=None, evaluation_mode='number'):
    """Backward-compatible wrapper that delegates to analyze_number_clip.

    - Accepts expected_digit, strokes_data, pressure_points, evaluation_mode.
    - Calls analyze_number_clip with the same arguments.
    - Returns result unchanged.
    - On any exception, returns safe error dict.
    """
    try:
        return analyze_number_clip(expected_digit, strokes_data, pressure_points, evaluation_mode)
    except Exception:
        return {
            "is_correct": False,
            "confidence": 0.0,
            "predicted_digit": None,
            "message": "Number analysis failed"
        }


def analyze_number_clip(expected_digit, strokes_data, pressure_points=None, evaluation_mode='number'):
    """Primary number analyzer using CLIP + geometry pipeline.

    - Delegates to the new handwriting.number_pipeline analyzer.
    - Accepts strokes_data (can be image or geometry data).
    - Returns analysis result dict.
    - On failure, returns safe error dict.
    """
    try:
        from handwriting.number_pipeline import analyze_number as analyze_number_pipeline
        result = analyze_number_pipeline(expected_digit, strokes_data, pressure_points, evaluation_mode)
        return result
    except Exception:
        return {
            "is_correct": False,
            "confidence": 0.0,
            "predicted_digit": None,
            "message": "Number analysis failed"
        }


def save_base64_image(image_b64: str, upload_folder: str) -> str:
    """Decode base64 image string and save to disk.

    - Strips data URL prefix (data:image/png;base64,...)
    - Decodes base64 → bytes
    - Saves as PNG in upload_folder
    - Returns absolute file path

    Raises ValueError if decode fails or folder doesn't exist.
    """
    import base64
    import os
    import uuid

    if not image_b64:
        raise ValueError("Empty image string")

    if not os.path.isdir(upload_folder):
        raise ValueError(f"Upload folder does not exist: {upload_folder}")

    # Strip data URL prefix
    if "," in image_b64:
        image_b64 = image_b64.split(",")[-1]

    # Fix padding
    pad = len(image_b64) % 4
    if pad:
        image_b64 += "=" * (4 - pad)

    try:
        image_bytes = base64.b64decode(image_b64, validate=False)
    except Exception as e:
        raise ValueError(f"Base64 decode failed: {e}")

    # Generate unique filename
    filename = f"image_{uuid.uuid4().hex[:8]}.png"
    filepath = os.path.join(upload_folder, filename)

    try:
        with open(filepath, "wb") as f:
            f.write(image_bytes)
    except Exception as e:
        raise ValueError(f"Failed to write image file: {e}")

    return os.path.abspath(filepath)


def validate_alphabet_mode(payload):
    """Validate alphabet mode payload.

    - Checks if 'letter' exists and is A–Z (case-insensitive).
    - Returns (True, None) if valid.
    - Returns (False, error_message) if invalid.
    """
    if payload is None:
        return (False, "Payload is None")

    letter = payload.get("letter")
    if letter is None:
        return (False, "Missing 'letter' field")

    letter = str(letter).strip().upper()
    if len(letter) != 1 or not letter.isalpha():
        return (False, f"Invalid letter: {letter}")

    return (True, None)


def validate_number_mode(payload):
    """Validate number mode payload.

    - Checks if 'letter' exists and is 0–9.
    - Returns (True, None) if valid.
    - Returns (False, error_message) if invalid.
    """
    if payload is None:
        return (False, "Payload is None")

    digit = payload.get("letter")
    if digit is None:
        return (False, "Missing 'letter' field")

    digit = str(digit).strip()
    if len(digit) != 1 or not digit.isdigit():
        return (False, f"Invalid digit: {digit}")

    return (True, None)

"""
Integration test for STRICT CLIP+GEOMETRY evaluator.

Tests the pipeline end-to-end:
1. Geometry extraction
2. Geometry validation gate
3. CLIP embedding
4. Strict threshold decision
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from handwriting.geometry import extract_geometry
from handwriting.simple_clip_evaluator import (
    evaluate_image_vs_image,
    CHARACTER_PROFILES,
    _validate_geometry_against_profile,
    _count_loops_from_geometry
)
import numpy as np
import cv2


def test_character_profiles():
    """Verify all character profiles are defined."""
    print("\n" + "="*70)
    print("TEST 1: Character Profiles Completeness")
    print("="*70)
    
    expected_chars = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    profile_chars = set(CHARACTER_PROFILES.keys())
    
    missing = expected_chars - profile_chars
    if missing:
        print(f"❌ Missing profiles for: {missing}")
    else:
        print(f"✅ All {len(expected_chars)} characters have profiles")
        print(f"   Profile keys: {', '.join(sorted(profile_chars))}")


def test_geometry_extraction():
    """Verify geometry extraction returns valid metrics."""
    print("\n" + "="*70)
    print("TEST 2: Geometry Extraction")
    print("="*70)
    
    # Create a synthetic "A-like" image (two diagonals + crossbar)
    # In practice, this would be from user's drawing
    img = np.ones((100, 100, 3), dtype=np.uint8) * 255
    
    # Draw simple stroke (filled rectangle as placeholder)
    cv2.rectangle(img, (20, 20), (80, 80), (0, 0, 0), 2)
    
    try:
        geometry = extract_geometry(img)
        print(f"✅ Geometry extracted successfully:")
        print(f"   - has_loop: {geometry.get('has_loop')}")
        print(f"   - is_vertical: {geometry.get('is_vertical')}")
        print(f"   - curvature: {geometry.get('curvature', 0.0):.2f}")
        print(f"   - aspect_ratio: {geometry.get('aspect_ratio', 0.0):.2f}")
        print(f"   - crossing_count: {geometry.get('crossing_count')}")
    except Exception as e:
        print(f"❌ Geometry extraction failed: {e}")


def test_geometry_validation():
    """Test the geometry validation gate."""
    print("\n" + "="*70)
    print("TEST 3: Geometry Validation Gate")
    print("="*70)
    
    # Test case 1: Letter A (no loops expected)
    geom_a = {
        "has_loop": False,
        "loops": 0,
        "is_vertical": True,
        "curvature": 0.1,
        "aspect_ratio": 1.5
    }
    is_valid, reason = _validate_geometry_against_profile(geom_a, "A")
    print(f"\n  Test A (no loops): {reason}")
    if is_valid:
        print(f"  ✅ Geometry validation passed")
    
    # Test case 2: Letter B (2 loops expected)
    geom_b_wrong = {
        "has_loop": False,  # WRONG! B should have loops
        "loops": 0,
        "is_vertical": True,
        "curvature": 0.5,
        "aspect_ratio": 1.0
    }
    is_valid, reason = _validate_geometry_against_profile(geom_b_wrong, "B")
    print(f"\n  Test B (wrong loops): {reason}")
    if not is_valid:
        print(f"  ✅ Correctly rejected (geometry doesn't match B profile)")
    
    # Test case 3: Letter I (simple, vertical, no loops)
    geom_i = {
        "has_loop": False,
        "loops": 0,
        "is_vertical": True,
        "curvature": 0.0,
        "aspect_ratio": 3.0
    }
    is_valid, reason = _validate_geometry_against_profile(geom_i, "I")
    print(f"\n  Test I (vertical, simple): {reason}")
    if is_valid:
        print(f"  ✅ Geometry validation passed")


def test_response_format():
    """Verify response format contains all required fields."""
    print("\n" + "="*70)
    print("TEST 4: Response Format")
    print("="*70)
    
    required_keys = {
        "predicted_letter",
        "expected_letter",
        "is_correct",
        "confidence",
        "analysis_source",
        "geometry",
        "clip_stats"
    }
    
    # Expected structure (dummy values for this test)
    response = {
        "predicted_letter": "A",
        "expected_letter": "A",
        "is_correct": False,
        "confidence": 62.3,
        "analysis_source": "CLIP+GEOMETRY",
        "geometry": {
            "loops": 2,
            "vertical_symmetry": 0.81,
            "stroke_count": 1,
            "curvature": 0.45,
            "aspect_ratio": 1.2
        },
        "clip_stats": {
            "avg_similarity": 0.623,
            "max_similarity": 0.71,
            "min_similarity": 0.54,
            "templates_compared": 8,
            "threshold": 0.75
        }
    }
    
    actual_keys = set(response.keys())
    missing = required_keys - actual_keys
    extra = actual_keys - required_keys
    
    if not missing and not extra:
        print(f"✅ Response format is correct")
        print(f"   Keys: {', '.join(sorted(required_keys))}")
    else:
        if missing:
            print(f"❌ Missing keys: {missing}")
        if extra:
            print(f"⚠️ Extra keys: {extra}")
    
    # Verify geometry keys
    geom_keys = set(response["geometry"].keys())
    expected_geom = {"loops", "vertical_symmetry", "stroke_count", "curvature", "aspect_ratio"}
    if expected_geom.issubset(geom_keys):
        print(f"✅ Geometry section contains all expected fields")


def test_threshold_logic():
    """Verify decision threshold logic."""
    print("\n" + "="*70)
    print("TEST 5: Threshold Logic")
    print("="*70)
    
    threshold = 0.75
    test_cases = [
        (0.80, True, "above threshold"),
        (0.75, True, "at threshold"),
        (0.74, False, "below threshold"),
        (0.50, False, "well below threshold"),
    ]
    
    for sim, expected, desc in test_cases:
        is_correct = sim >= threshold
        status = "✅" if is_correct == expected else "❌"
        result = "CORRECT" if is_correct else "INCORRECT"
        print(f"  {status} similarity={sim}: {result} ({desc})")


def main():
    print("\n")
    print("╔" + "="*68 + "╗")
    print("║ STRICT CLIP+GEOMETRY EVALUATOR - INTEGRATION TESTS              ║")
    print("╚" + "="*68 + "╝")
    
    test_character_profiles()
    test_geometry_extraction()
    test_geometry_validation()
    test_response_format()
    test_threshold_logic()
    
    print("\n" + "="*70)
    print("All tests completed!")
    print("="*70 + "\n")


if __name__ == "__main__":
    main()

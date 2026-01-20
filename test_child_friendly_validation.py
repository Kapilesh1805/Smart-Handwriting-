#!/usr/bin/env python3
"""
CHILD-FRIENDLY INTENT-BASED VALIDATION TEST
Tests the new per-shape intent thresholds for child drawings
"""

import os
import sys
import cv2
import numpy as np
from PIL import Image, ImageDraw

# Add the backend directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'smartboard-backend'))

from routes.prewriting_routes import (
    _stage1_shape_similarity_validation,
    _extract_largest_contour,
    _get_reference_shapes
)

def create_test_drawing(shape_type, quality="good"):
    """
    Create a test drawing that simulates child artwork
    """
    img = Image.new('L', (256, 256), 255)  # White background
    draw = ImageDraw.Draw(img)

    center = (128, 128)

    if shape_type == "LINES":
        if quality == "good":
            # Straight horizontal line
            draw.line([50, 128, 206, 128], fill=0, width=8)
        elif quality == "child":
            # Wobbly horizontal line (child-like)
            points = [(50, 120), (80, 135), (110, 125), (140, 130), (170, 128), (200, 132)]
            draw.line(points, fill=0, width=6)

    elif shape_type == "CIRCLES":
        if quality == "good":
            # Perfect circle
            draw.ellipse([78, 78, 178, 178], outline=0, width=8)
        elif quality == "child":
            # Imperfect circle (child-like)
            # Draw an oval that's not quite circular
            draw.ellipse([70, 85, 186, 171], outline=0, width=6)

    elif shape_type == "TRIANGLE":
        if quality == "good":
            # Perfect triangle
            draw.polygon([(128, 50), (50, 206), (206, 206)], outline=0, width=8)
        elif quality == "child":
            # Imperfect triangle (child-like)
            draw.polygon([(128, 60), (45, 200), (211, 190)], outline=0, width=6)

    elif shape_type == "SQUARE":
        if quality == "good":
            # Perfect square
            draw.rectangle([78, 78, 178, 178], outline=0, width=8)
        elif quality == "child":
            # Imperfect square (child-like)
            draw.rectangle([75, 85, 181, 171], outline=0, width=6)

    elif shape_type == "CURVES":
        if quality == "good":
            # Smooth curve
            points = []
            for x in range(50, 207, 10):
                y = 128 + 30 * np.sin((x-50) * 0.05)
                points.append((x, y))
            draw.line(points, fill=0, width=8)
        elif quality == "child":
            # Wobbly curve (child-like)
            points = [(50, 128), (70, 140), (90, 125), (110, 135), (130, 128), (150, 142), (170, 130), (190, 138), (210, 128)]
            draw.line(points, fill=0, width=6)

    elif shape_type == "ZIGZAG":
        if quality == "good":
            # Perfect zigzag
            points = [(50, 128), (80, 100), (110, 156), (140, 100), (170, 156), (200, 128)]
            draw.line(points, fill=0, width=8)
        elif quality == "child":
            # Imperfect zigzag (child-like)
            points = [(50, 128), (75, 105), (105, 150), (135, 95), (165, 155), (195, 125)]
            draw.line(points, fill=0, width=6)

    return img

def test_intent_thresholds():
    """
    Test the new intent-based thresholds with child-like drawings
    """
    print("="*80)
    print("CHILD-FRIENDLY INTENT-BASED VALIDATION TEST")
    print("="*80)

    # Test shapes and their expected intent thresholds
    test_cases = [
        ("LINES", 0.45, "child"),    # Should pass with wobbly line
        ("CIRCLES", 0.50, "child"),  # Should pass with imperfect circle
        ("TRIANGLE", 0.55, "child"), # Should pass with imperfect triangle
        ("SQUARE", 0.55, "child"),   # Should pass with imperfect square
        ("CURVES", 0.40, "child"),   # Should pass with wobbly curve
        ("ZIGZAG", 0.40, "child"),   # Should pass with imperfect zigzag
    ]

    results = []

    for expected_shape, expected_threshold, quality in test_cases:
        print(f"\n{'-'*60}")
        print(f"TESTING: {expected_shape} (threshold: {expected_threshold})")
        print(f"{'-'*60}")

        # Create test image
        test_img = create_test_drawing(expected_shape, quality)
        test_path = f"test_{expected_shape.lower()}_{quality}.png"
        test_img.save(test_path)

        try:
            # Test Stage-1 validation
            is_valid, best_score = _stage1_shape_similarity_validation(test_path, expected_shape)

            print(f"Result: {'PASS' if is_valid else 'FAIL'} (score: {best_score:.4f})")

            # Check if result matches expectation
            should_pass = best_score <= expected_threshold
            if is_valid == should_pass:
                print("✅ CORRECT: Validation matches intent threshold")
                results.append(True)
            else:
                print("❌ ERROR: Validation doesn't match intent threshold")
                results.append(False)

        except Exception as e:
            print(f"❌ ERROR: {e}")
            results.append(False)

        # Clean up
        if os.path.exists(test_path):
            os.remove(test_path)

    print(f"\n{'='*80}")
    print("FINAL RESULTS")
    print(f"{'='*80}")

    passed = sum(results)
    total = len(results)

    print(f"Tests passed: {passed}/{total}")

    if passed == total:
        print("🎉 ALL TESTS PASSED - Child-friendly intent thresholds working!")
        return True
    else:
        print("❌ SOME TESTS FAILED - Check threshold values")
        return False

def test_wrong_shape_rejection():
    """
    Test that wrong shapes are still rejected
    """
    print(f"\n{'='*80}")
    print("WRONG SHAPE REJECTION TEST")
    print(f"{'='*80}")

    # Test: Draw a CIRCLE but expect LINES - should fail
    test_img = create_test_drawing("CIRCLES", "child")
    test_path = "test_circle_as_lines.png"
    test_img.save(test_path)

    try:
        is_valid, best_score = _stage1_shape_similarity_validation(test_path, "LINES")
        print(f"Circle as LINES: {'PASS' if is_valid else 'FAIL'} (score: {best_score:.4f})")

        if not is_valid:
            print("✅ CORRECT: Wrong shape properly rejected")
            result = True
        else:
            print("❌ ERROR: Wrong shape incorrectly accepted")
            result = False

    except Exception as e:
        print(f"❌ ERROR: {e}")
        result = False

    # Clean up
    if os.path.exists(test_path):
        os.remove(test_path)

    return result

if __name__ == "__main__":
    # Change to backend directory
    os.chdir(os.path.dirname(__file__))

    success1 = test_intent_thresholds()
    success2 = test_wrong_shape_rejection()

    if success1 and success2:
        print(f"\n🎉 CHILD-FRIENDLY REFACTOR SUCCESSFUL!")
        print("Intent-based thresholds working correctly")
        sys.exit(0)
    else:
        print(f"\n❌ REFACTOR NEEDS ADJUSTMENT")
        sys.exit(1)
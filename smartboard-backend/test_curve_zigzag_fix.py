#!/usr/bin/env python3
"""
Test script for the fixed curve vs zigzag classification.
Tests the new curvature sign change logic.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from routes.prewriting_routes import _infer_shape_from_geometry, _compute_curvature_sign_changes
import cv2
import numpy as np

def create_test_contour(shape_type):
    """Create test contours for different shapes."""
    if shape_type == "smooth_curve":
        # Create a smooth curved line (like a gentle C-curve)
        points = []
        for t in np.linspace(0, np.pi, 30):
            x = int(20 + 60 * (1 - np.cos(t)))
            y = int(50 + 30 * np.sin(t))
            points.append([[x, y]])
        return np.array(points)

    elif shape_type == "zigzag":
        # Create a zigzag pattern with alternating directions
        points = []
        x = 10
        y = 50
        direction = 1
        for i in range(6):
            # Horizontal segment
            for _ in range(8):
                points.append([[x, y]])
                x += 2
            # Vertical turn
            for _ in range(6):
                y += direction * 2
                points.append([[x, y]])
            direction *= -1  # Change direction
        return np.array(points)

    elif shape_type == "wobbly_curve":
        # Create a wobbly curve with much more thickness
        points = []
        for t in np.linspace(0, 2*np.pi, 50):
            x = int(20 + 60 * t / (2*np.pi))
            # Add some wobble but keep it smooth, and make it much thicker
            y = int(50 + 30 * np.sin(t) + 10 * np.sin(3*t))
            points.append([[x, y]])
        return np.array(points)

    elif shape_type == "sharp_zigzag":
        # Create a very sharp zigzag with clear direction changes and some thickness
        points = []
        positions = [
            (10, 50), (25, 30), (40, 70), (55, 30), (70, 70), (85, 50),
            (85, 52), (70, 72), (55, 32), (40, 72), (25, 32), (10, 52)  # Add thickness
        ]
        for pos in positions:
            points.append([[pos[0], pos[1]]])
        return np.array(points)

    return None

def test_curvature_sign_changes():
    """Test the curvature sign change computation."""
    print("Testing Curvature Sign Changes...")
    print("=" * 50)

    test_cases = [
        ("smooth_curve", "Should have few sign changes"),
        ("zigzag", "Should have many sign changes"),
        ("wobbly_curve", "Should have moderate sign changes"),
        ("sharp_zigzag", "Should have many sign changes")
    ]

    for shape_input, description in test_cases:
        contour = create_test_contour(shape_input)
        if contour is not None:
            sign_changes = _compute_curvature_sign_changes(contour)
            print(f"{shape_input}: {sign_changes} sign changes - {description}")
        else:
            print(f"✗ Could not create {shape_input} contour")

    print()

def test_shape_inference():
    """Test the updated shape inference."""
    print("Testing Shape Inference with New Logic...")
    print("=" * 50)

    test_cases = [
        ("smooth_curve", "CURVES"),      # 0 sign changes, smooth
        ("zigzag", "ZIGZAG"),            # 5 sign changes, zigzag
        ("wobbly_curve", "ZIGZAG"),      # 12 sign changes, too wobbly for curve
        ("sharp_zigzag", "ZIGZAG")       # 7 sign changes, sharp zigzag
    ]

    for shape_input, expected_output in test_cases:
        contour = create_test_contour(shape_input)
        if contour is not None and len(contour) > 0:
            print(f"Created contour for {shape_input}: {len(contour)} points")
            # Check area and perimeter
            area = cv2.contourArea(contour)
            perimeter = cv2.arcLength(contour, True)
            print(f"  Area: {area:.1f}, Perimeter: {perimeter:.1f}")
            result = _infer_shape_from_geometry(contour)
            status = "✓" if result == expected_output else "✗"
            print(f"{status} {shape_input} → {result} (expected: {expected_output})")
        else:
            print(f"✗ {shape_input} → FAILED (contour creation failed)")

    print()

if __name__ == "__main__":
    print("🧪 Testing Fixed Curve vs Zigzag Classification")
    print("=" * 60)

    test_curvature_sign_changes()
    test_shape_inference()

    print("✅ Testing Complete!")
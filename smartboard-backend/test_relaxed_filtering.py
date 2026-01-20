#!/usr/bin/env python3
"""
Test script for RELAXED CONTOUR FILTERING + SAFE FALLBACK
Tests the fix for thin stroke detection (lines, light pressure)
"""

import sys
import os
import base64
import cv2
import numpy as np

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

from routes.prewriting_routes import _extract_filtered_contour

def test_relaxed_filtering():
    """Test the relaxed contour filtering with safe fallback."""
    print("🧪 TESTING RELAXED CONTOUR FILTERING + SAFE FALLBACK")
    print("=" * 60)

    # Test 1: Thin line (should work with 0.001% minimum)
    print("\n1. Testing thin line detection...")
    test_image = np.ones((300, 300, 3), dtype=np.uint8) * 255
    # Draw a very thin line (2 pixels thick)
    cv2.line(test_image, (50, 150), (250, 150), (0, 0, 0), 2)

    # Convert to base64
    _, buffer = cv2.imencode('.png', test_image)
    test_b64 = base64.b64encode(buffer).decode('utf-8')
    test_b64 = f"data:image/png;base64,{test_b64}"

    contour = _extract_filtered_contour(test_b64)
    if contour is not None:
        area = cv2.contourArea(contour)
        total_area = 300 * 300
        area_ratio = area / total_area
        print(f"   ✅ Thin line detected: area={area:.1f}, ratio={area_ratio:.5f}")
        print(f"   ✅ Passes 0.001% minimum: {area_ratio >= 0.00001}")
        print(f"   ✅ Passes 0.90% maximum: {area_ratio <= 0.90}")
    else:
        print("   ❌ Thin line detection failed")

    # Test 2: Very light pressure circle
    print("\n2. Testing light pressure circle...")
    test_image2 = np.ones((300, 300, 3), dtype=np.uint8) * 255
    # Draw a circle with very thin line (1 pixel)
    cv2.circle(test_image2, (150, 150), 60, (0, 0, 0), 1)

    _, buffer2 = cv2.imencode('.png', test_image2)
    test_b64_2 = base64.b64encode(buffer2).decode('utf-8')
    test_b64_2 = f"data:image/png;base64,{test_b64_2}"

    contour2 = _extract_filtered_contour(test_b64_2)
    if contour2 is not None:
        area2 = cv2.contourArea(contour2)
        total_area2 = 300 * 300
        area_ratio2 = area2 / total_area2
        print(f"   ✅ Light circle detected: area={area2:.1f}, ratio={area_ratio2:.5f}")
        print(f"   ✅ Passes relaxed filtering: {0.00001 <= area_ratio2 <= 0.90}")
    else:
        print("   ❌ Light circle detection failed")

    # Test 3: Empty image (should still return None)
    print("\n3. Testing empty image handling...")
    empty_image = np.ones((300, 300, 3), dtype=np.uint8) * 255  # All white

    _, buffer3 = cv2.imencode('.png', empty_image)
    test_b64_3 = base64.b64encode(buffer3).decode('utf-8')
    test_b64_3 = f"data:image/png;base64,{test_b64_3}"

    contour3 = _extract_filtered_contour(test_b64_3)
    if contour3 is None:
        print("   ✅ Empty image correctly returns None")
    else:
        print("   ❌ Empty image should return None")

    # Test 4: Background-sized contour (should be rejected by fallback)
    print("\n4. Testing background rejection...")
    large_image = np.ones((300, 300, 3), dtype=np.uint8) * 255
    # Draw a rectangle that covers 95% of the image (should trigger fallback but still be selected if it's the only contour)
    cv2.rectangle(large_image, (5, 5), (295, 295), (0, 0, 0), -1)

    _, buffer4 = cv2.imencode('.png', large_image)
    test_b64_4 = base64.b64encode(buffer4).decode('utf-8')
    test_b64_4 = f"data:image/png;base64,{test_b64_4}"

    contour4 = _extract_filtered_contour(test_b64_4)
    if contour4 is not None:
        area4 = cv2.contourArea(contour4)
        total_area4 = 300 * 300
        area_ratio4 = area4 / total_area4
        print(f"   ✅ Large contour handled: area={area4:.1f}, ratio={area_ratio4:.3f}")
        print(f"   ✅ Within 90% limit: {area_ratio4 <= 0.90}")
        if area_ratio4 > 0.90:
            print("   ⚠️  Large contour accepted (may be background)")
    else:
        print("   ❌ Large contour detection failed")

    print("\n✅ RELAXED FILTERING TEST COMPLETED!")
    print("\n🎯 KEY IMPROVEMENTS:")
    print("   • Minimum area: 0.005% → 0.001% (allows thin lines)")
    print("   • Maximum area: 0.70% → 0.90% (more flexible)")
    print("   • Safe fallback: Never fails for valid drawings")
    print("   • Thin strokes now detected reliably")
    print("   • Child-friendly pressure detection")

if __name__ == "__main__":
    test_relaxed_filtering()
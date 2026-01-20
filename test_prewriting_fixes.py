#!/usr/bin/env python3
"""
Test script to validate pre-writing shape analysis fixes.
Tests the two-stage pipeline:
1. STAGE 1: Shape identification
2. STAGE 2: Correctness check
"""

import json
import requests
import base64
import cv2
import numpy as np
from pathlib import Path

# Backend URL
BACKEND_URL = "http://127.0.0.1:5000/prewriting/analyze"

def create_test_image(shape_type, filename="test_image.png"):
    """
    Create a test image for different shapes.
    
    Args:
        shape_type: 'LINE', 'CURVE', 'CIRCLE', 'ZIGZAG', 'TRIANGLE', 'SQUARE'
        filename: Output filename
    
    Returns:
        Image array
    """
    img = np.ones((400, 400, 3), dtype=np.uint8) * 255
    
    if shape_type == "LINE":
        # Draw a straight horizontal line
        cv2.line(img, (50, 200), (350, 200), (0, 0, 0), 5)
    
    elif shape_type == "CURVE":
        # Draw a curved line
        pts = []
        for x in range(50, 351):
            y = 150 + 50 * np.sin((x - 50) / 50.0)
            pts.append([x, int(y)])
        pts = np.array(pts, dtype=np.int32)
        cv2.polylines(img, [pts], False, (0, 0, 0), 5)
    
    elif shape_type == "CIRCLE":
        # Draw a circle
        cv2.circle(img, (200, 200), 80, (0, 0, 0), 5)
    
    elif shape_type == "ZIGZAG":
        # Draw a zigzag
        pts = np.array([
            [50, 100], [100, 300], [150, 100], [200, 300], 
            [250, 100], [300, 300], [350, 100]
        ], dtype=np.int32)
        cv2.polylines(img, [pts], False, (0, 0, 0), 5)
    
    elif shape_type == "TRIANGLE":
        # Draw a triangle
        pts = np.array([[100, 100], [300, 100], [200, 300]], dtype=np.int32)
        cv2.drawContours(img, [pts], 0, (0, 0, 0), 5)
    
    elif shape_type == "SQUARE":
        # Draw a square
        cv2.rectangle(img, (100, 100), (300, 300), (0, 0, 0), 5)
    
    cv2.imwrite(filename, img)
    return img

def image_to_base64(image_path):
    """Convert image file to base64."""
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def test_shape_analysis(expected_shape, drawn_shape, description=""):
    """
    Test shape analysis by sending request to backend.
    
    Args:
        expected_shape: Shape user selected (LINES, CURVES, etc.)
        drawn_shape: Shape that was actually drawn (LINE, CURVE, etc.)
        description: Test description
    """
    print("\n" + "="*80)
    print(f"TEST: {description}")
    print(f"  Expected Shape: {expected_shape}")
    print(f"  Drawn Shape:    {drawn_shape}")
    print("="*80)
    
    # Create test image
    create_test_image(drawn_shape, "test_shape.png")
    
    # Convert to base64
    image_b64 = image_to_base64("test_shape.png")
    
    # Prepare request
    payload = {
        "child_id": "test_child_001",
        "image_b64": image_b64,
        "meta": {
            "shape": expected_shape
        }
    }
    
    try:
        response = requests.post(BACKEND_URL, json=payload, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            print(f"\n✅ Response received (status {response.status_code})")
            print(f"\n📊 ANALYSIS RESULT:")
            print(f"  Expected Shape:      {data.get('expected_shape')}")
            print(f"  Predicted Shape:     {data.get('predicted_shape')}")
            print(f"  Is Correct:          {data.get('is_correct')}")
            print(f"  Accuracy Score:      {data.get('accuracy_score')}%")
            print(f"  Overall Score:       {data.get('overall_score'):.1f}%")
            
            quality = data.get('quality_scores', {})
            print(f"\n🎨 QUALITY SCORES:")
            print(f"  Smoothness:          {quality.get('smoothness', 0):.1f}%")
            print(f"  Size Consistency:    {quality.get('size_consistency', 0):.1f}%")
            print(f"  Pressure Consistency:{quality.get('pressure_consistency', 0):.1f}%")
            
            print(f"\n💬 FEEDBACK:")
            print(f"  {data.get('feedback')}")
            
            # Validation
            print(f"\n✔️ VALIDATION:")
            expected_correct = (expected_shape.upper() in 
                              [drawn_shape.upper(), 
                               {'LINE': 'LINES', 'LINES': 'LINES', 'CURVE': 'CURVES', 
                                'CURVES': 'CURVES', 'CIRCLE': 'CIRCLES', 
                                'CIRCLES': 'CIRCLES'}.get(drawn_shape.upper(), drawn_shape.upper())])
            
            is_correct = data.get('is_correct')
            
            if expected_correct:
                if is_correct:
                    print(f"  ✅ PASS - Shapes match and is_correct=true")
                else:
                    print(f"  ❌ FAIL - Shapes match but is_correct=false")
            else:
                if not is_correct:
                    print(f"  ✅ PASS - Shapes differ and is_correct=false")
                else:
                    print(f"  ❌ FAIL - Shapes differ but is_correct=true")
                    
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
    
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to backend at {BACKEND_URL}")
        print(f"   Make sure the Flask backend is running!")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    return True

def main():
    """Run all tests."""
    print("\n" + "="*80)
    print("PRE-WRITING SHAPE ANALYSIS - TWO-STAGE PIPELINE TEST")
    print("="*80)
    
    # Test matrix: (expected, drawn, description)
    tests = [
        # ✅ CORRECT SCENARIOS
        ("LINES", "LINE", "User selects LINES, draws a straight line"),
        ("CURVES", "CURVE", "User selects CURVES, draws a smooth curve"),
        ("CIRCLE", "CIRCLE", "User selects CIRCLE, draws a circle"),
        ("CIRCLES", "CIRCLE", "User selects CIRCLES, draws a circle (singular/plural)"),
        ("ZIGZAG", "ZIGZAG", "User selects ZIGZAG, draws a zigzag pattern"),
        ("TRIANGLE", "TRIANGLE", "User selects TRIANGLE, draws a triangle"),
        ("SQUARE", "SQUARE", "User selects SQUARE, draws a square"),
        
        # ❌ INCORRECT SCENARIOS
        ("LINES", "CURVE", "User selects LINES, draws a curve (INCORRECT)"),
        ("CIRCLES", "ZIGZAG", "User selects CIRCLES, draws zigzag (INCORRECT)"),
        ("TRIANGLE", "SQUARE", "User selects TRIANGLE, draws square (INCORRECT)"),
        ("CURVE", "CIRCLE", "User selects CURVE, draws circle (INCORRECT)"),
        ("ZIGZAG", "TRIANGLE", "User selects ZIGZAG, draws triangle (INCORRECT)"),
    ]
    
    results = []
    for expected, drawn, desc in tests:
        if test_shape_analysis(expected, drawn, desc):
            results.append((desc, "TESTED"))
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    for desc, status in results:
        print(f"  {status}: {desc}")
    
    print(f"\nTotal tests run: {len(results)}")
    print("="*80 + "\n")

if __name__ == "__main__":
    main()

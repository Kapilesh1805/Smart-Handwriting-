"""
Quick test for pre-writing evaluator.
Tests all 5 shapes with synthetic test images.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from handwriting.prewriting_evaluator import evaluate_prewriting_shape
import base64
import numpy as np
import cv2
from PIL import Image
import io

def create_test_image(shape_type: str, width: int = 224, height: int = 224) -> str:
    """Create a synthetic test image for each shape."""
    
    # Create white background
    img = np.ones((height, width, 3), dtype=np.uint8) * 255
    
    if shape_type == "line":
        # Draw a straight line
        cv2.line(img, (30, 100), (200, 100), (0, 0, 0), 3)
    
    elif shape_type == "curve":
        # Draw a smooth curve
        points = []
        for x in range(30, 200):
            y = int(100 + 50 * np.sin((x - 30) / 20))
            points.append([x, y])
        points = np.array(points, dtype=np.int32)
        cv2.polylines(img, [points], False, (0, 0, 0), 3)
    
    elif shape_type == "circle":
        # Draw a circle
        cv2.circle(img, (112, 112), 60, (0, 0, 0), 3)
    
    elif shape_type == "square":
        # Draw a square
        cv2.rectangle(img, (50, 50), (174, 174), (0, 0, 0), 3)
    
    elif shape_type == "zigzag":
        # Draw a zigzag pattern
        points = np.array([
            [30, 80],
            [80, 130],
            [130, 80],
            [180, 130],
            [210, 80]
        ], dtype=np.int32)
        cv2.polylines(img, [points], False, (0, 0, 0), 3)
    
    # Convert PIL to base64
    pil_img = Image.fromarray(img)
    buffer = io.BytesIO()
    pil_img.save(buffer, format="PNG")
    img_base64 = base64.b64encode(buffer.getvalue()).decode("utf-8")
    
    return img_base64


def test_all_shapes():
    """Test all 5 shapes."""
    
    shapes = ["line", "curve", "circle", "square", "zigzag"]
    
    print("=" * 80)
    print("PRE-WRITING EVALUATOR TEST")
    print("=" * 80)
    
    for shape in shapes:
        print(f"\n📝 Testing: {shape.upper()}")
        print("-" * 80)
        
        try:
            # Create test image
            img_base64 = create_test_image(shape)
            
            # Evaluate
            result = evaluate_prewriting_shape(img_base64, shape)
            
            # Print results
            print(f"  is_correct: {result['is_correct']}")
            print(f"  score:      {result['score']:.1f}/100")
            print(f"  feedback:   {result['feedback']}")
            
            # Determine test pass/fail
            if result['score'] >= 50:
                print(f"  ✅ PASS (score {result['score']:.1f} >= 50)")
            else:
                print(f"  ❌ FAIL (score {result['score']:.1f} < 50)")
        
        except Exception as e:
            print(f"  ❌ ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "=" * 80)
    print("TEST COMPLETE")
    print("=" * 80)


def test_invalid_shape():
    """Test invalid shape name."""
    
    print("\n📝 Testing: INVALID SHAPE")
    print("-" * 80)
    
    try:
        img_base64 = create_test_image("line")
        result = evaluate_prewriting_shape(img_base64, "invalid_shape")
        
        if not result['is_correct']:
            print(f"  ✅ PASS (correctly rejected invalid shape)")
            print(f"  feedback: {result['feedback']}")
        else:
            print(f"  ❌ FAIL (should reject invalid shape)")
    
    except Exception as e:
        print(f"  ❌ ERROR: {e}")


def test_empty_canvas():
    """Test empty canvas."""
    
    print("\n📝 Testing: EMPTY CANVAS")
    print("-" * 80)
    
    try:
        # Create blank white image (no drawing)
        img = np.ones((224, 224, 3), dtype=np.uint8) * 255
        pil_img = Image.fromarray(img)
        buffer = io.BytesIO()
        pil_img.save(buffer, format="PNG")
        img_base64 = base64.b64encode(buffer.getvalue()).decode("utf-8")
        
        result = evaluate_prewriting_shape(img_base64, "line")
        
        if not result['is_correct']:
            print(f"  ✅ PASS (correctly rejected empty canvas)")
            print(f"  score: {result['score']:.1f}")
            print(f"  feedback: {result['feedback']}")
        else:
            print(f"  ❌ FAIL (should reject empty canvas)")
    
    except Exception as e:
        print(f"  ❌ ERROR: {e}")


if __name__ == "__main__":
    test_all_shapes()
    test_invalid_shape()
    test_empty_canvas()

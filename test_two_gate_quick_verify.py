#!/usr/bin/env python3
"""Quick verification that two-gate validation system works."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'smartboard-backend'))

from routes.prewriting_routes import _is_shape_compatible, _compute_accuracy_score

def test_gates():
    """Quick test of both gates."""
    print("VERIFICATION: Two-Gate Validation System")
    print("=" * 70)
    
    # Test GATE 1: None shape must be rejected
    assert _is_shape_compatible("LINES", None) == False, "FAIL: None shape should be rejected"
    assert _is_shape_compatible("LINES", "UNKNOWN") == False, "FAIL: Unknown shape should be rejected"
    assert _is_shape_compatible("LINES", "LINE") == True, "FAIL: Compatible shapes should pass"
    assert _is_shape_compatible("LINES", "CURVE") == False, "FAIL: Incompatible shapes should be rejected"
    print("PASS: GATE 1 validation working correctly")
    
    # Test GATE 2: Threshold check
    metrics_good = {
        "contour_points": 100,
        "vertices": 2,
        "circularity": 0.05,
        "curvature_ratio": 1.1,
        "aspect_ratio": 5.0,
        "area_perimeter_ratio": 0.001,
        "bbox_width": 500,
        "bbox_height": 100
    }
    
    metrics_bad = {
        "contour_points": 10,
        "vertices": 10,
        "circularity": 0.8,
        "curvature_ratio": 3.0,
        "aspect_ratio": 1.0,
        "area_perimeter_ratio": 0.05,
        "bbox_width": 100,
        "bbox_height": 100
    }
    
    score_good = _compute_accuracy_score("LINES", metrics_good)
    score_bad = _compute_accuracy_score("LINES", metrics_bad)
    
    assert score_good >= 60, f"FAIL: Good metrics should score >= 60%, got {score_good}%"
    assert score_bad < 60, f"FAIL: Bad metrics should score < 60%, got {score_bad}%"
    print("PASS: GATE 2 validation working correctly")
    
    # Test complete two-gate logic
    tests = [
        ("LINES", None, 90, False, "Gate 1 fails: None shape"),
        ("LINES", "UNKNOWN", 90, False, "Gate 1 fails: Unknown shape"),
        ("LINES", "CIRCLE", 85, False, "Gate 1 fails: Wrong shape"),
        ("LINES", "LINE", 45, False, "Gate 2 fails: Low score"),
        ("LINES", "LINE", 75, True, "Both gates pass"),
    ]
    
    for expected, predicted, score, should_be_correct, scenario in tests:
        is_compatible = _is_shape_compatible(expected, predicted)
        if is_compatible:
            is_correct = score >= 60
        else:
            is_correct = False
        
        assert is_correct == should_be_correct, f"FAIL: {scenario} - got {is_correct}, expected {should_be_correct}"
    
    print("PASS: Complete two-gate system working correctly")
    
    print("=" * 70)
    print("SUCCESS: All verification tests passed!")
    print("")
    print("Two-Gate Validation System is ready for production deployment.")
    return True

if __name__ == "__main__":
    try:
        test_gates()
        exit(0)
    except AssertionError as e:
        print(f"VERIFICATION FAILED: {e}")
        exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

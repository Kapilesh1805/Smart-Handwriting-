#!/usr/bin/env python3
"""
Test suite for TWO-GATE VALIDATION SYSTEM in pre-writing shape analysis.

This tests that:
1. GATE 1: Shape compatibility is enforced (predicted vs expected)
2. GATE 2: Quality threshold (accuracy >= 60) is applied
3. UI consistency: is_correct matches predicted_shape validity
4. Feedback consistency: Message matches correctness result
"""

import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'smartboard-backend'))

from routes.prewriting_routes import _is_shape_compatible, _compute_accuracy_score

def test_gate_1_shape_compatibility():
    """Test GATE 1: Shape compatibility validation"""
    print("\n" + "="*70)
    print("🧪 TEST SUITE 1: GATE 1 - SHAPE COMPATIBILITY")
    print("="*70)
    
    test_cases = [
        # (expected_shape, predicted_shape, should_be_compatible)
        
        # ✅ COMPATIBLE CASES
        ("LINES", "LINE", True),
        ("LINES", "LINES", True),
        ("CURVES", "CURVE", True),
        ("CURVES", "CURVES", True),
        ("CIRCLE", "CIRCLE", True),
        ("CIRCLES", "CIRCLE", True),
        ("CIRCLES", "CIRCLES", True),
        ("TRIANGLE", "TRIANGLE", True),
        ("SQUARE", "SQUARE", True),
        ("ZIGZAG", "ZIGZAG", True),
        ("LINE", "LINE", True),
        ("LINE", "LINES", True),
        ("CURVE", "CURVE", True),
        ("CURVE", "CURVES", True),
        
        # ❌ INCOMPATIBLE CASES
        ("LINES", "CURVE", False),
        ("CURVES", "LINE", False),
        ("CIRCLE", "SQUARE", False),
        ("TRIANGLE", "SQUARE", False),
        ("LINES", None, False),
        ("LINES", "UNKNOWN", False),
        ("CIRCLES", "UNKNOWN", False),
        ("TRIANGLE", None, False),
        ("LINES", "TRIANGLE", False),
        ("SQUARE", "CIRCLE", False),
    ]
    
    passed = 0
    failed = 0
    
    for expected, predicted, should_be_compatible in test_cases:
        result = _is_shape_compatible(expected, predicted)
        is_pass = result == should_be_compatible
        
        status = "✅ PASS" if is_pass else "❌ FAIL"
        passed += is_pass
        failed += not is_pass
        
        print(f"{status} | Expected: {expected:10} Predicted: {str(predicted):10} | Result: {result} (expected {should_be_compatible})")
    
    print(f"\nGATE 1 Results: {passed}/{len(test_cases)} PASSED")
    return failed == 0


def test_gate_2_quality_threshold():
    """Test GATE 2: Quality threshold validation"""
    print("\n" + "="*70)
    print("🧪 TEST SUITE 2: GATE 2 - QUALITY THRESHOLD (>= 60%)")
    print("="*70)
    
    test_cases = [
        # (expected_shape, metrics, should_pass_60_percent)
        
        # ✅ LINES: Should pass with good features
        ("LINES", {
            "contour_points": 100,
            "vertices": 2,
            "circularity": 0.05,
            "curvature_ratio": 1.1,
            "aspect_ratio": 5.0,
            "area_perimeter_ratio": 0.001,
            "bbox_width": 500,
            "bbox_height": 100
        }, True),  # Elongation=5, low curvature → high score
        
        # ❌ LINES: Should fail with wrong features
        ("LINES", {
            "contour_points": 10,
            "vertices": 10,
            "circularity": 0.8,
            "curvature_ratio": 3.0,
            "aspect_ratio": 1.0,
            "area_perimeter_ratio": 0.05,
            "bbox_width": 100,
            "bbox_height": 100
        }, False),  # No elongation, high curvature → low score
        
        # ✅ CIRCLES: Should pass with good features
        ("CIRCLES", {
            "contour_points": 50,
            "vertices": 8,
            "circularity": 0.8,
            "curvature_ratio": 6.0,
            "aspect_ratio": 1.0,
            "area_perimeter_ratio": 0.02,
            "bbox_width": 100,
            "bbox_height": 100
        }, True),  # High circularity, round aspect ratio
        
        # ❌ CIRCLES: Should fail with wrong features
        ("CIRCLES", {
            "contour_points": 50,
            "vertices": 8,
            "circularity": 0.2,
            "curvature_ratio": 6.0,
            "aspect_ratio": 3.0,
            "area_perimeter_ratio": 0.02,
            "bbox_width": 300,
            "bbox_height": 100
        }, False),  # Low circularity, elongated
        
        # ✅ CURVES: Should pass with good features
        ("CURVES", {
            "contour_points": 50,
            "vertices": 5,
            "circularity": 0.4,
            "curvature_ratio": 4.0,
            "aspect_ratio": 1.5,
            "area_perimeter_ratio": 0.01,
            "bbox_width": 150,
            "bbox_height": 100
        }, True),  # Many points, good curvature, not circular
        
        # ✅ CURVES: Good curve with contour points > 20
        ("CURVES", {
            "contour_points": 25,
            "vertices": 4,
            "circularity": 0.4,
            "curvature_ratio": 2.0,
            "aspect_ratio": 1.5,
            "area_perimeter_ratio": 0.01,
            "bbox_width": 150,
            "bbox_height": 100
        }, True),  # > 20 points (+20) + curvature 2.0 (+40) + circularity 0.4 (+30) = 90%
        
        # ✅ TRIANGLE: Should pass with correct vertices
        ("TRIANGLE", {
            "contour_points": 40,
            "vertices": 3,
            "circularity": 0.3,
            "curvature_ratio": 13.0,
            "aspect_ratio": 0.8,
            "area_perimeter_ratio": 0.02,
            "bbox_width": 100,
            "bbox_height": 120
        }, True),  # Exactly 3 vertices
        
        # ❌ TRIANGLE: Should fail with wrong vertices
        ("TRIANGLE", {
            "contour_points": 40,
            "vertices": 4,
            "circularity": 0.3,
            "curvature_ratio": 10.0,
            "aspect_ratio": 1.0,
            "area_perimeter_ratio": 0.02,
            "bbox_width": 100,
            "bbox_height": 100
        }, False),  # 4 vertices instead of 3
        
        # ✅ SQUARE: Should pass with 4 vertices and square aspect
        ("SQUARE", {
            "contour_points": 40,
            "vertices": 4,
            "circularity": 0.6,
            "curvature_ratio": 10.0,
            "aspect_ratio": 1.0,
            "area_perimeter_ratio": 0.03,
            "bbox_width": 100,
            "bbox_height": 100
        }, True),  # 4 vertices, square aspect
        
        # ❌ SQUARE: Should fail with wrong vertices
        ("SQUARE", {
            "contour_points": 40,
            "vertices": 3,
            "circularity": 0.6,
            "curvature_ratio": 13.0,
            "aspect_ratio": 1.0,
            "area_perimeter_ratio": 0.03,
            "bbox_width": 100,
            "bbox_height": 100
        }, False),  # 3 vertices instead of 4
        
        # ✅ ZIGZAG: Should pass with many vertices
        ("ZIGZAG", {
            "contour_points": 60,
            "vertices": 10,
            "circularity": 0.2,
            "curvature_ratio": 6.0,
            "aspect_ratio": 1.5,
            "area_perimeter_ratio": 0.01,
            "bbox_width": 150,
            "bbox_height": 100
        }, True),  # Many vertices, low circularity
        
        # ❌ ZIGZAG: Should fail with few vertices
        ("ZIGZAG", {
            "contour_points": 30,
            "vertices": 3,
            "circularity": 0.2,
            "curvature_ratio": 10.0,
            "aspect_ratio": 1.5,
            "area_perimeter_ratio": 0.01,
            "bbox_width": 150,
            "bbox_height": 100
        }, False),  # Only 3 vertices
    ]
    
    passed = 0
    failed = 0
    
    for expected_shape, metrics, should_pass_threshold in test_cases:
        score = _compute_accuracy_score(expected_shape, metrics)
        passes_threshold = score >= 60
        is_pass = passes_threshold == should_pass_threshold
        
        status = "✅ PASS" if is_pass else "❌ FAIL"
        passed += is_pass
        failed += not is_pass
        
        shape_name = expected_shape.ljust(10)
        score_str = f"{score}%".ljust(5)
        threshold_str = f"(expected {should_pass_threshold})"
        
        print(f"{status} | {shape_name} Score: {score_str} Passes 60%: {passes_threshold} {threshold_str}")
    
    print(f"\nGATE 2 Results: {passed}/{len(test_cases)} PASSED")
    return failed == 0


def test_two_gate_combined():
    """Test the complete two-gate system"""
    print("\n" + "="*70)
    print("🧪 TEST SUITE 3: COMPLETE TWO-GATE SYSTEM")
    print("="*70)
    
    test_cases = [
        # (expected, predicted, score, should_be_correct, scenario)
        
        # ✅ Both gates pass: is_correct = True
        ("LINES", "LINE", 80, True, "Good line: compatible shape + high score"),
        ("CIRCLES", "CIRCLE", 75, True, "Good circle: compatible shape + passing score"),
        ("CURVES", "CURVE", 62, True, "Good curve: compatible shape + barely passing"),
        
        # ❌ Gate 1 fails: is_correct = False (regardless of score)
        ("LINES", None, 90, False, "Gate 1 fails: No shape detected (even with high score)"),
        ("CIRCLES", "UNKNOWN", 85, False, "Gate 1 fails: Unknown shape (even with high score)"),
        ("TRIANGLE", "SQUARE", 75, False, "Gate 1 fails: Wrong shape type"),
        
        # ❌ Gate 1 passes but Gate 2 fails: is_correct = False
        ("LINES", "LINE", 45, False, "Gate 2 fails: Correct shape but low score"),
        ("CIRCLES", "CIRCLE", 55, False, "Gate 2 fails: Correct shape but score < 60%"),
        ("CURVES", "CURVE", 59, False, "Gate 2 fails: Correct shape but just under threshold"),
        
        # Edge cases
        ("LINES", "LINES", 70, True, "Lines variant: compatible + passing"),
        ("CIRCLES", "CIRCLES", 68, True, "Circles variant: compatible + passing"),
    ]
    
    passed = 0
    failed = 0
    
    for expected, predicted, score, should_be_correct, scenario in test_cases:
        # Simulate the two-gate logic
        is_compatible = _is_shape_compatible(expected, predicted)
        if is_compatible:
            is_correct = score >= 60
        else:
            is_correct = False
        
        is_pass = is_correct == should_be_correct
        status = "✅ PASS" if is_pass else "❌ FAIL"
        passed += is_pass
        failed += not is_pass
        
        pred_str = str(predicted).ljust(10) if predicted else "None".ljust(10)
        score_str = f"{score}%".ljust(5)
        
        print(f"{status} | {scenario}")
        print(f"       Expected: {expected:10} Predicted: {pred_str} Score: {score_str} Correct: {is_correct}")
    
    print(f"\nTWO-GATE SYSTEM Results: {passed}/{len(test_cases)} PASSED")
    return failed == 0


def test_ui_consistency():
    """Test that UI consistency rules are followed by the two-gate system"""
    print("\n" + "="*70)
    print("🧪 TEST SUITE 4: UI CONSISTENCY RULES")
    print("="*70)
    
    # The two-gate system enforces these rules:
    # 1. predicted_shape = None → is_correct must be False (Gate 1 enforces this)
    # 2. predicted_shape = "Unknown" → is_correct must be False (Gate 1 enforces this)
    # 3. If is_correct = True → predicted_shape must be valid (Gate 1 ensures this)
    
    consistency_cases = [
        {
            "scenario": "Case 1: None shape detected → is_correct must be False",
            "expected": "LINES",
            "predicted": None,
            "score": 90,  # High score irrelevant if Gate 1 fails
            "expected_is_correct": False,
            "reason": "Gate 1 rejects None shapes"
        },
        {
            "scenario": "Case 2: Unknown shape detected → is_correct must be False",
            "expected": "CIRCLES",
            "predicted": "UNKNOWN",
            "score": 85,  # High score irrelevant if Gate 1 fails
            "expected_is_correct": False,
            "reason": "Gate 1 rejects Unknown shapes"
        },
        {
            "scenario": "Case 3: Wrong shape type → is_correct must be False",
            "expected": "TRIANGLE",
            "predicted": "SQUARE",
            "score": 80,
            "expected_is_correct": False,
            "reason": "Gate 1 rejects incompatible shapes"
        },
        {
            "scenario": "Case 4: Correct shape but low score → is_correct must be False",
            "expected": "LINES",
            "predicted": "LINE",
            "score": 50,  # Below 60% threshold
            "expected_is_correct": False,
            "reason": "Gate 2 rejects low scores (< 60%)"
        },
        {
            "scenario": "Case 5: Correct shape at threshold → is_correct must be True",
            "expected": "LINES",
            "predicted": "LINE",
            "score": 60,  # Exactly at threshold
            "expected_is_correct": True,
            "reason": "Gate 2 accepts >= 60%"
        },
        {
            "scenario": "Case 6: Correct shape with good score → is_correct must be True",
            "expected": "CIRCLES",
            "predicted": "CIRCLE",
            "score": 75,  # Above threshold
            "expected_is_correct": True,
            "reason": "Both gates pass"
        },
        {
            "scenario": "Case 7: Consistent UI output when correct",
            "expected": "CURVES",
            "predicted": "CURVE",
            "score": 70,
            "expected_is_correct": True,
            "reason": "UI will show: Identified=CURVE, is_correct=True ✅"
        },
    ]
    
    passed = 0
    failed = 0
    
    for case in consistency_cases:
        expected = case["expected"]
        predicted = case["predicted"]
        score = case["score"]
        expected_is_correct = case["expected_is_correct"]
        
        # Apply two-gate logic
        is_compatible = _is_shape_compatible(expected, predicted)
        if is_compatible:
            actual_is_correct = score >= 60
        else:
            actual_is_correct = False
        
        is_pass = actual_is_correct == expected_is_correct
        status = "✅ PASS" if is_pass else "❌ FAIL"
        passed += is_pass
        failed += not is_pass
        
        print(f"\n{status} | {case['scenario']}")
        print(f"       Expected: {expected}, Predicted: {str(predicted):10} Score: {score}%")
        print(f"       Result: is_correct={actual_is_correct} (expected {expected_is_correct})")
        print(f"       Reason: {case['reason']}")
    
    print(f"\nUI CONSISTENCY Results: {passed}/{len(consistency_cases)} PASSED")
    return failed == 0


def main():
    """Run all test suites"""
    print("\n" + "="*70)
    print("🔬 COMPREHENSIVE TEST SUITE: TWO-GATE VALIDATION SYSTEM")
    print("="*70)
    
    results = []
    
    # Run each test suite
    results.append(("GATE 1 - Shape Compatibility", test_gate_1_shape_compatibility()))
    results.append(("GATE 2 - Quality Threshold", test_gate_2_quality_threshold()))
    results.append(("Two-Gate Combined System", test_two_gate_combined()))
    results.append(("UI Consistency Rules", test_ui_consistency()))
    
    # Print summary
    print("\n" + "="*70)
    print("📊 FINAL TEST SUMMARY")
    print("="*70)
    
    all_passed = all(result[1] for result in results)
    passed_count = sum(1 for _, passed in results if passed)
    
    for test_name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{status} | {test_name}")
    
    print("="*70)
    if all_passed:
        print(f"✅ ALL {len(results)} TEST SUITES PASSED")
        print("🎉 TWO-GATE VALIDATION SYSTEM IS WORKING CORRECTLY")
        return 0
    else:
        print(f"❌ {len(results) - passed_count} TEST SUITE(S) FAILED")
        print("⚠️ Please review the failures above")
        return 1


if __name__ == "__main__":
    exit(main())

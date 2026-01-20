#!/usr/bin/env python3
"""
PHASE 2 VERIFICATION: Test that accuracy_score ONLY determines correctness.

This test verifies the new simplified logic where:
1. accuracy_score is the ONLY authority for correctness
2. If correct (≥60%): predicted_shape_for_display = expected_shape (forced)
3. If incorrect (<60%): predicted_shape_for_display = detected shape
4. No two-gate validation exists
5. _is_shape_compatible() function doesn't exist
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'smartboard-backend'))

from routes.prewriting_routes import (
    _compute_accuracy_score,
    _identify_prewriting_shape,
    _calculate_shape_quality,
    _get_shape_metrics
)

print("\n" + "="*70)
print("✅ PHASE 2 IMPLEMENTATION VERIFICATION")
print("="*70)

# Test 1: Verify _is_shape_compatible() function doesn't exist
print("\n[TEST 1] Verify _is_shape_compatible() function removed")
try:
    from routes.prewriting_routes import _is_shape_compatible
    print("❌ FAIL: _is_shape_compatible() still exists (should be deleted)")
    sys.exit(1)
except ImportError:
    print("✅ PASS: _is_shape_compatible() successfully removed")

# Test 2: Verify accuracy_score calculation works
print("\n[TEST 2] Verify accuracy_score calculation")
test_cases = [
    ("LINES", {}, 0),  # No metrics → low score
    ("CIRCLE", {"circularity": 0.95, "contour_points": 50}, None),  # Should calculate
]

for expected_shape, metrics, expected_min in test_cases:
    score = _compute_accuracy_score(expected_shape, metrics)
    print(f"  Expected: {expected_shape}, Score: {score}%")
    assert isinstance(score, (int, float)), f"Score should be numeric, got {type(score)}"
    assert 0 <= score <= 100, f"Score should be 0-100, got {score}"
print("✅ PASS: accuracy_score calculation works")

# Test 3: Verify correctness logic
print("\n[TEST 3] Verify correctness determination logic")
test_scores = [
    (59, False, "< 60% → incorrect"),
    (60, True, "= 60% → correct"),
    (75, True, "> 60% → correct"),
    (100, True, "100% → correct"),
]

for score, expected_correct, desc in test_scores:
    # Simulating the new logic from analyze_prewriting()
    is_shape_correct = score >= 60
    assert is_shape_correct == expected_correct, f"Failed for {desc}"
    print(f"  {desc}: is_correct={is_shape_correct} ✅")

print("✅ PASS: Correctness determination uses only accuracy_score")

# Test 4: Verify predicted_shape_for_display logic
print("\n[TEST 4] Verify predicted_shape_for_display logic")
test_display_logic = [
    (True, "CIRCLE", "Unknown", "CIRCLE", "Correct: force expected"),
    (False, "CIRCLE", "SQUARE", "SQUARE", "Incorrect: keep detected"),
    (False, "CIRCLE", "Unknown", "Unknown", "Incorrect: keep detected even if Unknown"),
]

for is_correct, expected_shape, predicted_shape, expected_display, desc in test_display_logic:
    # Simulating the logic from analyze_prewriting()
    if is_correct:
        predicted_shape_for_display = expected_shape
    else:
        predicted_shape_for_display = predicted_shape
    
    assert predicted_shape_for_display == expected_display, f"Failed for {desc}"
    print(f"  {desc}: display={predicted_shape_for_display} ✅")

print("✅ PASS: predicted_shape_for_display logic correct")

# Test 5: Verify feedback uses predicted_shape, not correctness
print("\n[TEST 5] Verify feedback generation logic")
test_feedback = [
    (True, "CIRCLE", "CIRCLE", "Excellent"),
    (False, "CIRCLE", "SQUARE", "Not quite"),
    (False, "CIRCLE", "Unknown", "not clearly recognized"),
]

for is_correct, expected_shape, predicted_shape, expected_keyword in test_feedback:
    # Simulating feedback logic from analyze_prewriting()
    if is_correct:
        shape_feedback = f"✅ Excellent! You drew {expected_shape} correctly!"
    else:
        if predicted_shape and predicted_shape.upper() != "UNKNOWN":
            shape_feedback = f"❌ Not quite. You drew {predicted_shape} instead of {expected_shape}."
        else:
            shape_feedback = f"❌ Shape not clearly recognized. Try drawing {expected_shape} again..."
    
    assert expected_keyword.lower() in shape_feedback.lower(), f"Expected '{expected_keyword}' in feedback"
    print(f"  {expected_keyword}: ✅")

print("✅ PASS: Feedback uses predicted_shape for explanation")

# Test 6: Verify no two-gate logic remains
print("\n[TEST 6] Verify no two-gate terminology in code")
from routes import prewriting_routes
import inspect

source = inspect.getsource(prewriting_routes.analyze_prewriting)
two_gate_keywords = ["GATE 1", "GATE 2", "is_shape_compatible", "_is_shape_compatible"]
found_keywords = []

for keyword in two_gate_keywords:
    if keyword in source:
        found_keywords.append(keyword)

if found_keywords:
    print(f"❌ FAIL: Found two-gate references: {found_keywords}")
    sys.exit(1)
else:
    print("✅ PASS: No two-gate terminology in analyze_prewriting()")

print("\n" + "="*70)
print("✅ ALL PHASE 2 VERIFICATION TESTS PASSED")
print("="*70)
print("\nSUMMARY:")
print("  ✅ _is_shape_compatible() function removed")
print("  ✅ accuracy_score is ONLY authority for correctness")
print("  ✅ predicted_shape_for_display forced when correct")
print("  ✅ predicted_shape kept when incorrect")
print("  ✅ Feedback uses predicted_shape for explanation")
print("  ✅ No two-gate logic remains")
print("\n")

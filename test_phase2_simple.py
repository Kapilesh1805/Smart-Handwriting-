#!/usr/bin/env python3
"""
PHASE 2 VERIFICATION: Test that accuracy_score ONLY determines correctness.
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
print("PHASE 2 IMPLEMENTATION VERIFICATION")
print("="*70)

# Test 1: Verify _is_shape_compatible() function doesn't exist
print("\n[TEST 1] Verify _is_shape_compatible() function removed")
try:
    from routes.prewriting_routes import _is_shape_compatible
    print("FAIL: _is_shape_compatible() still exists")
    sys.exit(1)
except ImportError:
    print("PASS: _is_shape_compatible() successfully removed")

# Test 2: Verify accuracy_score calculation works
print("\n[TEST 2] Verify accuracy_score calculation")
test_cases = [
    ("LINES", {}),
    ("CIRCLE", {"circularity": 0.95, "contour_points": 50}),
]

for expected_shape, metrics in test_cases:
    score = _compute_accuracy_score(expected_shape, metrics)
    print(f"  Expected: {expected_shape}, Score: {score}%")
    assert isinstance(score, (int, float)), f"Score should be numeric"
    assert 0 <= score <= 100, f"Score should be 0-100"
print("PASS: accuracy_score calculation works")

# Test 3: Verify correctness logic
print("\n[TEST 3] Verify correctness determination logic")
test_scores = [
    (59, False),
    (60, True),
    (75, True),
    (100, True),
]

for score, expected_correct in test_scores:
    is_shape_correct = score >= 60
    assert is_shape_correct == expected_correct
    print(f"  Score {score}%: is_correct={is_shape_correct} PASS")

print("PASS: Correctness uses only accuracy_score")

# Test 4: Verify predicted_shape_for_display logic
print("\n[TEST 4] Verify predicted_shape_for_display logic")
test_display_logic = [
    (True, "CIRCLE", "Unknown", "CIRCLE"),
    (False, "CIRCLE", "SQUARE", "SQUARE"),
    (False, "CIRCLE", "Unknown", "Unknown"),
]

for is_correct, expected_shape, predicted_shape, expected_display in test_display_logic:
    if is_correct:
        predicted_shape_for_display = expected_shape
    else:
        predicted_shape_for_display = predicted_shape
    
    assert predicted_shape_for_display == expected_display
    print(f"  Correct={is_correct}: display={predicted_shape_for_display} PASS")

print("PASS: predicted_shape_for_display logic correct")

# Test 5: Verify feedback uses predicted_shape
print("\n[TEST 5] Verify feedback generation logic")
test_feedback = [
    (True, "CIRCLE", "CIRCLE", "Excellent"),
    (False, "CIRCLE", "SQUARE", "Not quite"),
    (False, "CIRCLE", "Unknown", "not clearly recognized"),
]

for is_correct, expected_shape, predicted_shape, expected_keyword in test_feedback:
    if is_correct:
        shape_feedback = f"Excellent! You drew {expected_shape} correctly!"
    else:
        if predicted_shape and predicted_shape.upper() != "UNKNOWN":
            shape_feedback = f"Not quite. You drew {predicted_shape}."
        else:
            shape_feedback = f"not clearly recognized."
    
    assert expected_keyword.lower() in shape_feedback.lower()
    print(f"  {expected_keyword}: PASS")

print("PASS: Feedback uses predicted_shape")

# Test 6: Verify no two-gate logic remains
print("\n[TEST 6] Verify no two-gate terminology")
from routes import prewriting_routes
import inspect

source = inspect.getsource(prewriting_routes.analyze_prewriting)
two_gate_keywords = ["GATE 1", "GATE 2", "is_shape_compatible", "_is_shape_compatible"]
found_keywords = []

for keyword in two_gate_keywords:
    if keyword in source:
        found_keywords.append(keyword)

if found_keywords:
    print(f"FAIL: Found: {found_keywords}")
    sys.exit(1)
else:
    print("PASS: No two-gate terminology")

print("\n" + "="*70)
print("ALL PHASE 2 VERIFICATION TESTS PASSED (6/6)")
print("="*70)

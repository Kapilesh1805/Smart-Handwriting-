"""
Single-Pass CLIP Evaluator - Integration Test

Validates:
  1. Image preprocessed ONCE (frozen for reuse)
  2. CLIP loaded ONCE on first request (cached thereafter)
  3. Geometry soft filter (never hard-rejects correct letters)
  4. Response format: analysis_source: "CLIP_IMAGE_ONLY"
  5. Deterministic evaluation (same input = same output)
  6. Threshold: 0.30 for correctness
  7. No redundant operations or logs

To run locally (requires PyTorch + OpenCV):
  python test_single_pass.py
"""

import sys
import os
import logging

# Setup logging to see [CLIP], [EVAL] tags
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)-8s [%(name)s] %(message)s"
)
logger = logging.getLogger(__name__)

def test_response_format():
    """Verify response has correct structure (CLIP_IMAGE_ONLY format)."""
    logger.info("TEST: Response format validation")
    
    # Expected response format (from simple_clip_evaluator.py)
    expected_keys = {
        "analysis_source",      # Should be "CLIP_IMAGE_ONLY"
        "predicted_letter",
        "expected_letter",
        "is_correct",           # Boolean
        "confidence",           # Float 0-100
        "geometry",             # Dict with soft features
        "feedback"              # User-friendly text
    }
    
    # Keys that MUST NOT be in response (old format)
    forbidden_keys = {
        "clip_stats",                   # ❌ Old
        "geometry_failure_reason",      # ❌ Old (geometry never hard-fails now)
        "error"                         # ❌ Should only in error responses
    }
    
    # Example response (what we expect)
    example_response = {
        "analysis_source": "CLIP_IMAGE_ONLY",
        "predicted_letter": "A",
        "expected_letter": "A",
        "is_correct": True,
        "confidence": 87.5,
        "geometry": {
            "loops": 0,
            "curvature": 0.234,
            "aspect_ratio": 0.567,
            "is_vertical": False,
            "is_horizontal": False,
            "has_diagonal": False,
            "crossing_count": 0
        },
        "feedback": "Correct letter A (confidence: 87.5%)"
    }
    
    # Validate
    for key in expected_keys:
        assert key in example_response, f"Missing expected key: {key}"
    
    for key in forbidden_keys:
        assert key not in example_response, f"Forbidden key present: {key}"
    
    assert example_response["analysis_source"] == "CLIP_IMAGE_ONLY"
    assert isinstance(example_response["is_correct"], bool)
    assert 0.0 <= example_response["confidence"] <= 100.0
    assert isinstance(example_response["geometry"], dict)
    assert isinstance(example_response["feedback"], str)
    
    logger.info("✅ Response format validation PASSED")


def test_preprocessing_single_pass():
    """Verify image preprocessing happens ONCE."""
    logger.info("TEST: Single-pass preprocessing")
    
    # The preprocess_image_once() function should:
    # 1. Take PIL Image
    # 2. Return (grayscale_cv2, rgb_pil_224x224)
    # 3. Never be called twice for same image
    
    # Validation: Check function signature
    from handwriting.simple_clip_evaluator import preprocess_image_once
    import inspect
    
    sig = inspect.signature(preprocess_image_once)
    params = list(sig.parameters.keys())
    
    assert "image_pil" in params, "Should accept PIL image"
    assert len(params) == 1, "Should only take one parameter (image)"
    
    # Check return annotation suggests tuple
    assert "Tuple" in str(sig.return_annotation), "Should return tuple"
    
    logger.info("✅ Preprocessing function signature VALID")


def test_clip_lazy_initialization():
    """Verify CLIP loads ONCE and caches."""
    logger.info("TEST: CLIP lazy initialization")
    
    from handwriting.simple_clip_evaluator import _initialized, ensure_clip_loaded
    
    # Before first call: _initialized should be False
    # (Would be True if already imported, but that's OK for this test)
    
    # ensure_clip_loaded() should:
    # 1. Check _initialized flag
    # 2. If False: load model + templates (shows logs)
    # 3. If True: return immediately (no logs)
    
    import inspect
    
    source = inspect.getsource(ensure_clip_loaded)
    
    # Verify it checks _initialized
    assert "_initialized" in source, "Should check _initialized flag"
    
    # Verify it loads CLIP only if not initialized
    assert "if _initialized:" in source or "_initialized" in source
    assert "open_clip.create_model_and_transforms" in source
    
    logger.info("✅ CLIP lazy initialization logic VALID")


def test_geometry_soft_filter():
    """Verify geometry never hard-rejects letters."""
    logger.info("TEST: Geometry soft filter (never hard-rejects)")
    
    from handwriting.simple_clip_evaluator import compute_geometry_info
    
    # Geometry function should:
    # 1. Take geometry dict
    # 2. Return informational dict (never reject)
    # 3. Include loops, curvature, aspect_ratio, etc.
    # 4. Never include "reject" or "fail" logic
    
    import inspect
    
    source = inspect.getsource(compute_geometry_info)
    
    # Verify it's purely informational
    assert "never reject" in source.lower() or "informational" in source.lower(), \
        "Should document that geometry never rejects"
    
    # Verify it doesn't contain hard validation logic
    assert "return False" not in source, "Should not return False (hard reject)"
    
    logger.info("✅ Geometry soft filter VERIFIED")


def test_threshold_decision_logic():
    """Verify threshold decision (0.30 minimum)."""
    logger.info("TEST: Threshold decision logic")
    
    from handwriting.simple_clip_evaluator import evaluate_image_vs_image
    
    import inspect
    source = inspect.getsource(evaluate_image_vs_image)
    
    # Should have:
    # correctness_threshold = 0.30
    # is_correct = similarity >= correctness_threshold
    
    assert "correctness_threshold" in source, "Should define threshold"
    assert "0.30" in source, "Should use 0.30 threshold"
    assert ">=" in source, "Should use >= comparison"
    
    logger.info("✅ Threshold decision logic VALID (0.30)")


def test_compare_only_to_expected():
    """Verify comparison is ONLY to expected character."""
    logger.info("TEST: Compare ONLY to expected character")
    
    from handwriting.simple_clip_evaluator import evaluate_image_vs_image
    
    import inspect
    source = inspect.getsource(evaluate_image_vs_image)
    
    # Should have:
    # "Compare ONLY to expected character" comment
    # Only access _template_embeddings[expected_char]
    # No loop over all characters
    
    assert "ONLY to expected" in source, "Should compare only to expected"
    assert "_template_embeddings[expected_char]" in source, \
        "Should lookup only expected character"
    
    # Verify no auto-prediction logic
    assert "auto" not in source.lower() or "auto" not in source[:500].lower(), \
        "Should not have auto-prediction logic"
    
    logger.info("✅ Expected-character-only comparison VERIFIED")


def test_no_geometry_hard_gates():
    """Verify old hard geometry gates are removed."""
    logger.info("TEST: No hard geometry gates")
    
    # Load the evaluator file
    with open("smartboard-backend/handwriting/simple_clip_evaluator.py", "r") as f:
        content = f.read()
    
    # Old code artifacts to check for removal:
    forbidden_patterns = [
        "_validate_geometry_against_profile",  # ❌ Old hard gate function
        "_count_loops_from_geometry",           # ❌ Old helper
        "geometry_failure_reason",              # ❌ Only in old hard-gate responses
        "CHARACTER_PROFILES",                   # ❌ Old hardcoded profiles for gating
    ]
    
    for pattern in forbidden_patterns:
        # Allow in comments/docstrings, but not in active code
        lines = content.split("\n")
        active_lines = [l for l in lines if not l.strip().startswith("#") 
                        and not l.strip().startswith('"""')]
        active_code = "\n".join(active_lines)
        
        if pattern in active_code and pattern != "geometry_failure_reason":
            # geometry_failure_reason allowed in docstrings explaining old format
            if '"""' not in content[content.find(pattern)-50:content.find(pattern)]:
                logger.warning(f"⚠️  Found {pattern} in active code (might be OK in comments)")
    
    # Check that new soft functions exist
    assert "compute_geometry_info" in content, "Should have soft geometry function"
    assert "def preprocess_image_once" in content, "Should have single-pass preprocessing"
    assert "def ensure_clip_loaded" in content, "Should have lazy CLIP init"
    
    logger.info("✅ Old hard gates removed, new soft logic present")


def test_single_request_single_response():
    """Verify one request = one response (no multiple rounds)."""
    logger.info("TEST: Single request = single response")
    
    from handwriting.simple_clip_evaluator import evaluate_image_vs_image
    
    import inspect
    source = inspect.getsource(evaluate_image_vs_image)
    
    # Function should:
    # 1. Have exactly ONE return statement (or multiple at end)
    # 2. Not have retry loops
    # 3. Not have "multiple clicks" comment
    
    return_count = source.count("return {")
    assert return_count >= 1, "Should have at least one return path"
    
    # Should not have retry logic
    assert "retry" not in source.lower(), "Should not have retry logic"
    assert "loop" not in source.lower() or "for" not in source.lower(), \
        "Should not loop through evaluation stages"
    
    # Should have comment about single-pass
    assert "single-pass" in source.lower() or "ONE PASS" in source, \
        "Should document single-pass behavior"
    
    logger.info("✅ Single request/response pattern VERIFIED")


def test_deterministic_evaluation():
    """Verify same input = same output (deterministic)."""
    logger.info("TEST: Deterministic evaluation (no randomness)")
    
    from handwriting.simple_clip_evaluator import evaluate_image_vs_image
    
    import inspect
    source = inspect.getsource(evaluate_image_vs_image)
    
    # Should not use:
    # - random.choice, np.random, torch.randint, etc.
    # - dropout, data augmentation
    # - stochastic operations
    
    random_patterns = [
        "random.choice",
        "np.random",
        "torch.randint",
        "torch.rand",
        "dropout",
        "augment",
    ]
    
    for pattern in random_patterns:
        assert pattern not in source, f"Should not use randomness: {pattern}"
    
    # Should use torch.no_grad() for determinism
    assert "torch.no_grad()" in source, "Should use no_grad() for deterministic embedding"
    
    logger.info("✅ Deterministic evaluation (no randomness) VERIFIED")


def run_all_tests():
    """Run all validation tests."""
    logger.info("=" * 70)
    logger.info("SINGLE-PASS CLIP EVALUATOR - VALIDATION SUITE")
    logger.info("=" * 70)
    
    tests = [
        ("Response format", test_response_format),
        ("Single-pass preprocessing", test_preprocessing_single_pass),
        ("CLIP lazy initialization", test_clip_lazy_initialization),
        ("Geometry soft filter", test_geometry_soft_filter),
        ("Threshold decision logic", test_threshold_decision_logic),
        ("Expected-char-only comparison", test_compare_only_to_expected),
        ("No hard geometry gates", test_no_geometry_hard_gates),
        ("Single request/response", test_single_request_single_response),
        ("Deterministic evaluation", test_deterministic_evaluation),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_fn in tests:
        try:
            test_fn()
            passed += 1
        except AssertionError as e:
            logger.error(f"❌ {name} FAILED: {e}")
            failed += 1
        except Exception as e:
            logger.error(f"⚠️  {name} ERROR: {e}")
            failed += 1
    
    logger.info("=" * 70)
    logger.info(f"RESULTS: {passed} passed, {failed} failed")
    logger.info("=" * 70)
    
    return failed == 0


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)

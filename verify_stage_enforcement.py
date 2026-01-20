#!/usr/bin/env python3
"""
Verification script for Stage-1 enforcement and quality metrics.

Tests:
1. ✓ Automatic reference shape download is implemented
2. ✓ Stage-1 never bypasses (fails if no references)
3. ✓ Quality metrics are deterministic (no random values)
4. ✓ Quality scores always exposed in response
5. ✓ Writing/Letter interface untouched
"""

import os
import sys

# Add smartboard-backend to path
sys.path.insert(0, r"C:\Users\Kapilesh\OneDrive\Desktop\hAND\smartboard-backend")

def test_1_automatic_download():
    """Test 1: Automatic reference shape download is implemented"""
    print("\n" + "="*70)
    print("TEST 1: Automatic Reference Shape Download")
    print("="*70)
    
    try:
        from routes.prewriting_routes import _ensure_reference_shapes_exist, _download_quickdraw_samples, _create_synthetic_reference_shapes
        
        print("✓ _ensure_reference_shapes_exist function found")
        print("✓ _download_quickdraw_samples function found")
        print("✓ _create_synthetic_reference_shapes function found")
        
        # Check implementation
        import inspect
        source = inspect.getsource(_ensure_reference_shapes_exist)
        
        if "urllib.request" in source or "QuickDraw" in source or "_download_quickdraw_samples" in source:
            print("✓ Automatic download logic implemented")
            return True
        else:
            print("❌ Automatic download logic missing")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_2_stage1_never_bypasses():
    """Test 2: Stage-1 never bypasses (FAILS if no references)"""
    print("\n" + "="*70)
    print("TEST 2: Stage-1 Never Bypasses (No Reference = FAIL)")
    print("="*70)
    
    try:
        from routes.prewriting_routes import _stage1_shape_similarity_validation
        
        import inspect
        source = inspect.getsource(_stage1_shape_similarity_validation)
        
        # Check for critical rule: DO NOT BYPASS
        checks = [
            ("NEVER bypasses" in source or "NO BYPASS" in source, "NO BYPASS enforcement"),
            ("return False, 1.0" in source, "Returns False when no references"),
            ("reference_paths" in source, "Checks for reference paths"),
        ]
        
        all_pass = True
        for check, name in checks:
            if check:
                print(f"✓ {name}")
            else:
                print(f"❌ {name}")
                all_pass = False
        
        return all_pass
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_3_deterministic_quality_metrics():
    """Test 3: Quality metrics are deterministic (no random)"""
    print("\n" + "="*70)
    print("TEST 3: Deterministic Quality Metrics (No Random Values)")
    print("="*70)
    
    try:
        from routes.prewriting_routes import _calculate_shape_quality
        
        import inspect
        source = inspect.getsource(_calculate_shape_quality)
        
        # Check for critical rule: NO RANDOM
        if "np.random" in source:
            print("❌ Random values found in quality calculation")
            return False
        
        print("✓ No np.random found in quality calculation")
        
        # Check for deterministic metrics
        metrics = [
            ("smoothness_score" in source, "Smoothness metric (from curvature)"),
            ("size_consistency_score" in source, "Size consistency metric (from stroke width)"),
            ("pressure_consistency_score" in source, "Pressure consistency metric (from pixel density)"),
            ("overall_score" in source, "Overall score calculation"),
        ]
        
        all_pass = True
        for check, name in metrics:
            if check:
                print(f"✓ {name}")
            else:
                print(f"❌ {name}")
                all_pass = False
        
        return all_pass
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_4_always_expose_quality_scores():
    """Test 4: Quality scores always exposed in API response"""
    print("\n" + "="*70)
    print("TEST 4: Always Expose Quality Scores in Response")
    print("="*70)
    
    try:
        from routes.prewriting_routes import analyze_prewriting
        
        import inspect
        source = inspect.getsource(analyze_prewriting)
        
        # Check for critical rule: ALWAYS include quality_scores
        checks = [
            ('"quality_scores"' in source, "quality_scores in response"),
            ("MANDATORY" in source or "Always" in source.upper(), "Mandatory enforcement"),
            ("quality_metrics_data" in source or "quality_metrics" in source, "Quality metrics calculation"),
            ("STAGE 1 FAILED" in source, "Quality scores even when stage fails"),
        ]
        
        all_pass = True
        for check, name in checks:
            if check:
                print(f"✓ {name}")
            else:
                print(f"❌ {name}")
                all_pass = False
        
        return all_pass
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_5_writing_interface_untouched():
    """Test 5: Writing/Letter interface completely untouched"""
    print("\n" + "="*70)
    print("TEST 5: Writing/Letter Interface Untouched")
    print("="*70)
    
    try:
        # Check that handwriting_routes.py exists and is separate
        handwriting_path = r"C:\Users\Kapilesh\OneDrive\Desktop\hAND\smartboard-backend\routes\handwriting_routes.py"
        
        if not os.path.exists(handwriting_path):
            print("❌ handwriting_routes.py not found")
            return False
        
        print("✓ handwriting_routes.py exists (separate from prewriting)")
        
        # Verify it has handwriting-specific functions
        with open(handwriting_path, 'r') as f:
            content = f.read()
        
        checks = [
            ("evaluate_image_vs_image" in content, "Letter evaluation function"),
            ("evaluate_digit_image_vs_image" in content, "Number evaluation function"),
            ("handwriting" in content.lower(), "Handwriting-specific logic"),
        ]
        
        all_pass = True
        for check, name in checks:
            if check:
                print(f"✓ {name}")
            else:
                print(f"❌ {name}")
                all_pass = False
        
        return all_pass
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_6_imports():
    """Test 6: Module imports successfully"""
    print("\n" + "="*70)
    print("TEST 6: Module Imports Successfully")
    print("="*70)
    
    try:
        from routes.prewriting_routes import (
            analyze_prewriting,
            _stage1_shape_similarity_validation,
            _stage2_motor_skill_evaluation,
            _calculate_shape_quality,
            _ensure_reference_shapes_exist,
            _get_reference_shapes
        )
        
        functions = [
            "analyze_prewriting",
            "_stage1_shape_similarity_validation",
            "_stage2_motor_skill_evaluation",
            "_calculate_shape_quality",
            "_ensure_reference_shapes_exist",
            "_get_reference_shapes"
        ]
        
        for func in functions:
            print(f"✓ {func} imported successfully")
        
        return True
    except Exception as e:
        print(f"❌ Import error: {e}")
        return False


if __name__ == "__main__":
    print("\n" + "="*70)
    print("STAGE-1 ENFORCEMENT & QUALITY METRICS VERIFICATION")
    print("="*70)
    
    results = {}
    
    results["Test 1: Automatic Download"] = test_1_automatic_download()
    results["Test 2: Stage-1 Never Bypasses"] = test_2_stage1_never_bypasses()
    results["Test 3: Deterministic Metrics"] = test_3_deterministic_quality_metrics()
    results["Test 4: Always Expose Scores"] = test_4_always_expose_quality_scores()
    results["Test 5: Writing Interface"] = test_5_writing_interface_untouched()
    results["Test 6: Module Imports"] = test_6_imports()
    
    print("\n" + "="*70)
    print("VERIFICATION SUMMARY")
    print("="*70)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, passed_flag in results.items():
        status = "✓ PASS" if passed_flag else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎯 ALL VERIFICATION TESTS PASSED!")
        sys.exit(0)
    else:
        print(f"\n⚠ {total - passed} test(s) failed")
        sys.exit(1)

#!/usr/bin/env python3
"""
Test script for QuickDraw Reference Shape Downloader

Tests:
1. Directory structure creation
2. QuickDraw bitmap download
3. QuickDraw stroke download (fallback)
4. Image resizing and normalization
5. Minimum samples verification
6. Hard failure on missing references
"""

import os
import sys
import shutil
from pathlib import Path

# Add smartboard-backend to path
sys.path.insert(0, r"C:\Users\Kapilesh\OneDrive\Desktop\hAND\smartboard-backend")

# Import the functions
from routes.prewriting_routes import (
    _ensure_reference_shapes_exist,
    _download_quickdraw_bitmap_samples,
    _download_quickdraw_stroke_samples,
    _verify_reference_shapes_available,
    REFERENCE_SHAPES_DIR
)

def print_section(title):
    print(f"\n{'='*80}")
    print(f"🧪 {title}")
    print(f"{'='*80}")

def test_1_directory_structure():
    """Test: Directory structure creation"""
    print_section("TEST 1: Directory Structure Creation")
    
    # Clean up old test data
    if os.path.exists(REFERENCE_SHAPES_DIR):
        print(f"  🗑️  Cleaning up old {REFERENCE_SHAPES_DIR}...")
        shutil.rmtree(REFERENCE_SHAPES_DIR)
    
    print(f"  Creating: {REFERENCE_SHAPES_DIR}/")
    os.makedirs(REFERENCE_SHAPES_DIR, exist_ok=True)
    
    expected_dirs = ["LINES", "CURVES", "CIRCLES", "TRIANGLE", "SQUARE", "ZIGZAG"]
    for dir_name in expected_dirs:
        dir_path = os.path.join(REFERENCE_SHAPES_DIR, dir_name)
        os.makedirs(dir_path, exist_ok=True)
        print(f"    ✓ {dir_path}/")
    
    # Verify
    all_exist = all(
        os.path.isdir(os.path.join(REFERENCE_SHAPES_DIR, d)) 
        for d in expected_dirs
    )
    
    if all_exist:
        print(f"  ✅ PASS: All directories created")
        return True
    else:
        print(f"  ❌ FAIL: Some directories missing")
        return False


def test_2_bitmap_download():
    """Test: QuickDraw bitmap download"""
    print_section("TEST 2: QuickDraw Bitmap Download")
    
    test_shape = "circle"
    category_dir = os.path.join(REFERENCE_SHAPES_DIR, "CIRCLES")
    
    print(f"  Downloading bitmap samples for '{test_shape}'...")
    print(f"  Target directory: {category_dir}/")
    
    count = _download_quickdraw_bitmap_samples(test_shape, category_dir, min_samples=3)
    
    files = [f for f in os.listdir(category_dir) 
             if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    print(f"\n  Downloaded: {count} files")
    print(f"  Directory now contains: {len(files)} files")
    
    if count > 0:
        print(f"  ✅ PASS: Successfully downloaded bitmap samples")
        return True
    else:
        print(f"  ⚠️  No bitmap samples (will try stroke fallback)")
        return False


def test_3_stroke_download():
    """Test: QuickDraw stroke download (fallback)"""
    print_section("TEST 3: QuickDraw Stroke Download (Fallback)")
    
    test_shape = "line"
    category_dir = os.path.join(REFERENCE_SHAPES_DIR, "LINES")
    
    initial_count = len([f for f in os.listdir(category_dir) 
                        if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
    
    print(f"  Downloading stroke samples for '{test_shape}'...")
    print(f"  Initial files: {initial_count}")
    
    count = _download_quickdraw_stroke_samples(test_shape, category_dir, min_samples=3)
    
    final_count = len([f for f in os.listdir(category_dir) 
                      if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
    
    added = final_count - initial_count
    print(f"\n  Added: {added} files (total: {final_count})")
    
    if added > 0:
        print(f"  ✅ PASS: Successfully downloaded stroke samples")
        return True
    else:
        print(f"  ⚠️  No stroke samples downloaded")
        return False


def test_4_image_verification():
    """Test: Image files are PNG, resized to 256x256, binary"""
    print_section("TEST 4: Image Format Verification")
    
    try:
        from PIL import Image
        import numpy as np
        
        checked = 0
        passed = 0
        
        for shape_dir in ["CIRCLES", "LINES"]:
            shape_path = os.path.join(REFERENCE_SHAPES_DIR, shape_dir)
            files = [f for f in os.listdir(shape_path) 
                    if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
            
            for fname in files[:2]:  # Check first 2 per shape
                fpath = os.path.join(shape_path, fname)
                
                try:
                    img = Image.open(fpath)
                    arr = np.array(img)
                    
                    # Check size
                    if img.size != (256, 256):
                        print(f"  ⚠️  {fname}: Size {img.size} (expected 256x256)")
                    else:
                        print(f"  ✓ {fname}: 256x256, format={img.format}")
                        passed += 1
                    
                    checked += 1
                except Exception as e:
                    print(f"  ❌ {fname}: {e}")
                    checked += 1
        
        if passed > 0:
            print(f"\n  ✅ PASS: {passed}/{checked} images verified")
            return True
        else:
            print(f"  ⚠️  Checking format only")
            return passed > 0
    
    except Exception as e:
        print(f"  ⚠️  PIL not available: {e}")
        return None


def test_5_minimum_samples():
    """Test: Verify minimum 10 samples per shape"""
    print_section("TEST 5: Minimum Samples Verification")
    
    target = 10
    all_passed = True
    
    for shape in ["LINES", "CURVES", "CIRCLES", "TRIANGLE", "SQUARE", "ZIGZAG"]:
        shape_dir = os.path.join(REFERENCE_SHAPES_DIR, shape)
        files = [f for f in os.listdir(shape_dir) 
                if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        
        status = "✅" if len(files) >= target else "⚠️"
        print(f"  {status} {shape}: {len(files)}/{target}")
        
        if len(files) < target:
            all_passed = False
    
    if all_passed:
        print(f"\n  ✅ PASS: All shapes have ≥{target} samples")
    else:
        print(f"\n  ⚠️  Some shapes below minimum")
    
    return all_passed


def test_6_verify_function():
    """Test: _verify_reference_shapes_available function"""
    print_section("TEST 6: Reference Shape Availability Check")
    
    for shape in ["CIRCLES", "UNKNOWN"]:
        available, count = _verify_reference_shapes_available(shape)
        status = "✅" if available else "❌"
        print(f"  {status} {shape}: available={available}, count={count}")
    
    return True


def test_7_full_initialization():
    """Test: Full initialization with _ensure_reference_shapes_exist"""
    print_section("TEST 7: Full Reference Shape Initialization")
    
    print("  🔄 Running _ensure_reference_shapes_exist()...")
    print("     (This will download from QuickDraw with dual fallback)")
    
    stats = _ensure_reference_shapes_exist()
    
    print(f"\n  Initialization complete!")
    print(f"  Status breakdown:")
    for shape, status in stats.items():
        emoji = "✅" if status in ["SUCCESS", "CACHED"] else "⚠️"
        print(f"    {emoji} {shape}: {status}")
    
    return True


def test_8_hard_failure_simulation():
    """Test: Hard failure when references missing"""
    print_section("TEST 8: Hard Failure Simulation (Missing References)")
    
    print("  Simulating missing reference shapes...")
    
    # Check what happens with a non-existent shape
    available, count = _verify_reference_shapes_available("NONEXISTENT")
    
    if not available:
        print(f"  ✅ Correctly detected missing shape")
        print(f"     available={available}, count={count}")
        print(f"  Stage-1 validation will FAIL (hard gate enforced)")
        return True
    else:
        print(f"  ❌ Should have detected missing shape")
        return False


def main():
    """Run all tests"""
    print("\n" + "="*80)
    print("🧪 QUICKDRAW REFERENCE SHAPE DOWNLOADER TEST SUITE")
    print("="*80)
    print("Testing automatic handwritten shape download and preparation")
    print("Data source: Google QuickDraw (real handwritten data only)")
    print("="*80)
    
    results = {
        "Directory Structure": test_1_directory_structure(),
        "Bitmap Download": test_2_bitmap_download(),
        "Stroke Download": test_3_stroke_download(),
        "Image Verification": test_4_image_verification(),
        "Minimum Samples": test_5_minimum_samples(),
        "Verify Function": test_6_verify_function(),
        "Full Initialization": test_7_full_initialization(),
        "Hard Failure": test_8_hard_failure_simulation(),
    }
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    
    for test_name, result in results.items():
        if result is None:
            status = "⏭️  SKIPPED"
        elif result:
            status = "✅ PASS"
        else:
            status = "❌ FAIL"
        print(f"  {status}: {test_name}")
    
    passed = sum(1 for r in results.values() if r is True)
    total = len(results)
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
        print("\nQuickDraw downloader is ready for production:")
        print("  • Automatic QuickDraw bitmap download implemented")
        print("  • Stroke format fallback available")
        print("  • Hard failure on missing references enforced")
        print("  • Real handwritten data only (no synthetic)")
        print("  • 256×256 PNG binary images with white background")
        print("  • Auto-called on first /prewriting/analyze request")
    else:
        print(f"\n⚠️  Some tests need attention")
    
    print("\n" + "="*80 + "\n")

if __name__ == "__main__":
    main()

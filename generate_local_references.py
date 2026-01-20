#!/usr/bin/env python3
"""
Generate local reference shapes for offline Stage-1 validation.

These are SIMPLE GEOMETRIC references (NOT handwritten QuickDraw data).
Used for testing the offline Stage-1 validation system.

In production, replace these with real handwritten samples from:
- Downloaded QuickDraw samples (cached locally)
- Kaggle handwritten datasets
- IAM / EMNIST shape subsets
- GitHub handwritten shape repositories
"""

import os
import numpy as np
from PIL import Image, ImageDraw
import sys

def create_line_reference(filename, angle_offset=0):
    """Create a simple line reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw a line with slight variation based on offset
    start_x = 30 + angle_offset * 2
    start_y = 30
    end_x = 226 - angle_offset * 2
    end_y = 226
    
    draw.line([(start_x, start_y), (end_x, end_y)], fill='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def create_curve_reference(filename, intensity=0):
    """Create a simple curve reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw an arc/curve using multiple connected points
    points = []
    for x in range(30, 226):
        # Sine wave with intensity variation
        y = 128 + int(50 * np.sin((x - 30) / 40 + intensity * 0.5))
        points.append((x, y))
    
    draw.line(points, fill='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def create_circle_reference(filename, radius_offset=0):
    """Create a simple circle reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw a circle
    center_x, center_y = 128, 128
    radius = 80 + radius_offset
    
    bbox = [
        center_x - radius,
        center_y - radius,
        center_x + radius,
        center_y + radius
    ]
    
    draw.ellipse(bbox, outline='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def create_triangle_reference(filename, rotation=0):
    """Create a simple triangle reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw a triangle pointing up
    angle = rotation
    center_x, center_y = 128, 128
    size = 70
    
    # Calculate vertices (isoceles triangle)
    import math
    points = []
    for i in range(3):
        theta = angle + (i * 2 * math.pi / 3)
        x = center_x + int(size * math.cos(theta))
        y = center_y + int(size * math.sin(theta))
        points.append((x, y))
    
    # Close the triangle
    points.append(points[0])
    
    draw.line(points, fill='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def create_square_reference(filename, tilt=0):
    """Create a simple square reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw a square
    margin = 50 + tilt
    points = [
        (margin, margin),
        (256 - margin, margin),
        (256 - margin, 256 - margin),
        (margin, 256 - margin),
        (margin, margin)  # Close the square
    ]
    
    draw.line(points, fill='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def create_zigzag_reference(filename, amplitude=1):
    """Create a simple zigzag reference image."""
    img = Image.new('RGB', (256, 256), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw a zigzag pattern
    points = []
    zigzag_amplitude = 20 * amplitude
    
    for x in range(30, 226):
        if ((x - 30) // 20) % 2 == 0:
            y = 128 + zigzag_amplitude
        else:
            y = 128 - zigzag_amplitude
        points.append((x, y))
    
    draw.line(points, fill='black', width=4)
    img.save(filename)
    print(f"  ✓ Created: {filename}")


def generate_all_references():
    """Generate all reference shapes for offline Stage-1 validation."""
    print("\n" + "="*80)
    print("GENERATING LOCAL REFERENCE SHAPES (OFFLINE ONLY)")
    print("="*80)
    print("\nThese are SIMPLE GEOMETRIC references for testing.")
    print("In production, replace with REAL handwritten samples from:")
    print("  - Manually downloaded QuickDraw (preferred)")
    print("  - Kaggle handwritten datasets")
    print("  - IAM / EMNIST-style datasets")
    print("  - Public GitHub handwritten repositories\n")
    
    reference_dir = "reference_shapes"
    
    # Create LINES references
    print("📝 Generating LINES references...")
    lines_dir = os.path.join(reference_dir, "LINES")
    os.makedirs(lines_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(lines_dir, f"line_{i+1:02d}.png")
        create_line_reference(filename, angle_offset=i % 4)
    
    # Create CURVES references
    print("\n📝 Generating CURVES references...")
    curves_dir = os.path.join(reference_dir, "CURVES")
    os.makedirs(curves_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(curves_dir, f"curve_{i+1:02d}.png")
        create_curve_reference(filename, intensity=i % 3)
    
    # Create CIRCLES references
    print("\n📝 Generating CIRCLES references...")
    circles_dir = os.path.join(reference_dir, "CIRCLES")
    os.makedirs(circles_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(circles_dir, f"circle_{i+1:02d}.png")
        create_circle_reference(filename, radius_offset=(i % 4) * 2)
    
    # Create TRIANGLE references
    print("\n📝 Generating TRIANGLE references...")
    triangle_dir = os.path.join(reference_dir, "TRIANGLE")
    os.makedirs(triangle_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(triangle_dir, f"triangle_{i+1:02d}.png")
        import math
        create_triangle_reference(filename, rotation=(i % 6) * math.pi / 3)
    
    # Create SQUARE references
    print("\n📝 Generating SQUARE references...")
    square_dir = os.path.join(reference_dir, "SQUARE")
    os.makedirs(square_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(square_dir, f"square_{i+1:02d}.png")
        create_square_reference(filename, tilt=i % 5)
    
    # Create ZIGZAG references
    print("\n📝 Generating ZIGZAG references...")
    zigzag_dir = os.path.join(reference_dir, "ZIGZAG")
    os.makedirs(zigzag_dir, exist_ok=True)
    for i in range(12):
        filename = os.path.join(zigzag_dir, f"zigzag_{i+1:02d}.png")
        create_zigzag_reference(filename, amplitude=(i % 4) + 1)
    
    print("\n" + "="*80)
    print("✅ LOCAL REFERENCE GENERATION COMPLETE")
    print("="*80)
    print("\n📊 Reference Summary:")
    print("  ✓ LINES:     12 references created")
    print("  ✓ CURVES:    12 references created")
    print("  ✓ CIRCLES:   12 references created")
    print("  ✓ TRIANGLE:  12 references created")
    print("  ✓ SQUARE:    12 references created")
    print("  ✓ ZIGZAG:    12 references created")
    print("\n  Total: 72 local reference images")
    print("\n⚠️  IMPORTANT NOTES:")
    print("  - These are GEOMETRIC references for testing ONLY")
    print("  - Stage-1 validation will work with these")
    print("  - For REAL validation, replace with handwritten samples:")
    print("    1. Download from QuickDraw (cache locally)")
    print("    2. Use Kaggle datasets (save to reference_shapes/)")
    print("    3. Use IAM / EMNIST subsets")
    print("    4. Use GitHub handwritten shape repositories")
    print("\n  - Format required: 256×256 PNG, black on white")
    print("  - Minimum: 10 images per shape (12+ recommended)")
    print("\n🔗 Recommended data sources:")
    print("  - QuickDraw: https://quickdraw.google.com/")
    print("  - Kaggle: https://kaggle.com/ (search 'handwritten shapes')")
    print("  - IAM: https://fki.tic.heia-fr.ch/databases/iam-handwriting-database")
    print("  - GitHub: Search 'handwritten shape recognition'")
    print("="*80 + "\n")


if __name__ == "__main__":
    generate_all_references()
    print("\n✅ Reference shapes are ready for offline Stage-1 validation")
    print("   Run: python smartboard-backend/routes/prewriting_routes.py")
    print("   Or:  python -m flask run")

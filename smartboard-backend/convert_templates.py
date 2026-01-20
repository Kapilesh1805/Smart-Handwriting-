#!/usr/bin/env python3
"""
Convert PNG templates to normalized .npy contour files for the final pre-writing system.
"""

import os
import cv2
import numpy as np

def normalize_contour(contour):
    """Normalize contour: float32, center to origin, L2 normalize."""
    try:
        # Convert to float32
        contour = contour.astype(np.float32)

        # Calculate centroid
        moments = cv2.moments(contour)
        if moments['m00'] == 0:
            return contour

        cx = moments['m10'] / moments['m00']
        cy = moments['m01'] / moments['m00']

        # Center to origin
        centered = contour - np.array([cx, cy])

        # Normalize by scale (L2 norm)
        norm = np.linalg.norm(centered)
        if norm > 0:
            normalized = centered / norm
        else:
            normalized = centered

        return normalized.astype(np.float32)

    except Exception as e:
        print(f"❌ Contour normalization error: {e}")
        return contour

def convert_templates():
    """Convert PNG templates to normalized .npy files."""
    templates_dir = "templates"
    shapes = ["LINES", "CURVES", "CIRCLES", "TRIANGLE", "SQUARE", "ZIGZAG"]

    print("🔄 Converting PNG templates to normalized .npy files...")

    for shape in shapes:
        png_path = os.path.join(templates_dir, f"{shape.lower()}_canonical.png")
        npy_path = os.path.join(templates_dir, f"{shape.lower()}_canonical.npy")

        if not os.path.exists(png_path):
            print(f"❌ PNG template not found: {png_path}")
            continue

        try:
            # Load template image
            template_image = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
            if template_image is None:
                print(f"❌ Failed to load: {png_path}")
                continue

            # Extract contour from template
            _, binary = cv2.threshold(template_image, 127, 255, cv2.THRESH_BINARY_INV)
            contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            if not contours:
                print(f"❌ No contours found in: {png_path}")
                continue

            # Get the largest contour and normalize it
            template_contour = max(contours, key=cv2.contourArea)
            normalized_contour = normalize_contour(template_contour)

            # Save as .npy file
            np.save(npy_path, normalized_contour)
            print(f"✅ Converted {shape}: {len(normalized_contour)} points")

        except Exception as e:
            print(f"❌ Error converting {shape}: {e}")

    print("✅ Template conversion completed!")

if __name__ == "__main__":
    convert_templates()
def test_geometric_pre_gate():
    """Test shape inference from geometry"""
    import cv2
    import numpy as np
    import sys
    sys.path.append('smartboard-backend')
    from routes.prewriting_routes import _infer_shape_from_geometry

    # Create a perfect circle contour
    circle_contour = np.array([
        [[50, 0]], [[60, 10]], [[70, 20]], [[80, 30]], [[90, 40]], [[100, 50]],
        [[90, 60]], [[80, 70]], [[70, 80]], [[60, 90]], [[50, 100]],
        [[40, 90]], [[30, 80]], [[20, 70]], [[10, 60]], [[0, 50]],
        [[10, 40]], [[20, 30]], [[30, 20]], [[40, 10]], [[50, 0]]
    ], dtype=np.int32)

    # Circle should be inferred as CIRCLES
    inferred, reason = _infer_shape_from_geometry(circle_contour)
    assert inferred == "CIRCLES", f"Circle should be inferred as CIRCLES, got {inferred}: {reason}"

    # Test open line
    line_contour = np.array([
        [[0, 10]], [[10, 10]], [[20, 10]], [[30, 10]], [[40, 10]], [[50, 10]],
        [[60, 10]], [[70, 10]], [[80, 10]], [[90, 10]], [[100, 10]]
    ], dtype=np.int32)

    inferred, reason = _infer_shape_from_geometry(line_contour)
    assert inferred == "LINES", f"Open line should be inferred as LINES, got {inferred}: {reason}"

    print("✅ Shape inference test PASSED")
    return True

if __name__ == "__main__":
    test_geometric_pre_gate()
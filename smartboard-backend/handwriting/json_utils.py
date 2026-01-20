import json
import numpy as np


def sanitize_for_json(obj):
    """Recursively convert numpy and torch types to native Python types."""
    # Lazy import torch to avoid hard dependency here
    try:
        import torch
    except Exception:
        torch = None

    if obj is None:
        return None
    if isinstance(obj, (str, int, float, bool)):
        return obj
    if torch is not None and isinstance(obj, torch.Tensor):
        val = obj.cpu().numpy()
        return sanitize_for_json(val)
    if isinstance(obj, np.generic):
        return obj.item()
    if isinstance(obj, dict):
        return {str(k): sanitize_for_json(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [sanitize_for_json(v) for v in obj]
    try:
        return json.loads(json.dumps(obj))
    except Exception:
        return str(obj)

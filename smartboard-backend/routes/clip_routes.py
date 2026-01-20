from flask import Blueprint, request, jsonify
import base64
import io
import os
from PIL import Image

from clip_engine import ensure_clip_loaded, predict_letter_with_clip, compute_clip_similarity

clip_bp = Blueprint("clip", __name__, url_prefix="/clip")


def _lazy_load_clip():
    global _clip_loaded, _clip, _torch, _preprocess, _device
    # If we've previously determined clip is unavailable, avoid repeated import attempts
    global _clip_available
    if _clip_available is False:
        return False
    if _clip_loaded:
        _clip_available = True
        return True
    try:
        import torch
        import clip
        from torchvision import transforms

        _torch = torch
        _clip = clip
        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        # Use CLIP's preprocess pipeline
        _preprocess = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=(0.48145466, 0.4578275, 0.40821073), std=(0.26862954, 0.26130258, 0.27577711))
        ])

        # load model
        _clip_loaded = True
        _clip_available = True
        # do not actually load model weights here to keep startup light; load on first compute
        return True
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        msg = str(e)
        print(f"CLIP lazy-load failed: {msg}\n{tb}")
        # If it's a ModuleNotFoundError for torch/clip, give actionable instructions once
        if isinstance(e, ModuleNotFoundError) or 'No module named' in msg:
            print("\nMissing heavy dependencies for CLIP. To enable CLIP, activate the project's virtualenv and install the CPU builds (or GPU if available):")
            print("PowerShell (from project root):")
            print("  & '.\\.venv\\Scripts\\Activate.ps1'")
            print("  python -m pip install --upgrade pip")
            print("  python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu")
            print("  python -m pip install git+https://github.com/openai/CLIP.git")
            print("")
            _clip_loaded = False
            _clip_available = False
        else:
            # For non-import errors (binary mismatch, runtime problems), allow retries by leaving availability unknown
            _clip_loaded = False
            _clip_available = None
        return False


def _load_model_if_needed():
    global _clip, _torch, _device, _preprocess
    if not _lazy_load_clip():
        return None
    try:
        if not hasattr(_clip, 'available_models'):
            # ensure clip module is usable
            pass
        # load model into device and capture clip's preprocess (preferred)
        model, preprocess = _clip.load("ViT-B/32", device=_device)
        # prefer the preprocess returned by clip.load if available
        if preprocess is not None:
            _preprocess = preprocess
        model.eval()
        return model
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        print(f"Failed to load CLIP model: {e}\n{tb}")
        # mark availability unknown so reload attempts can retry
        global _clip_available
        _clip_available = None
        return None


def _image_from_path(path):
    with open(path, "rb") as f:
        return Image.open(io.BytesIO(f.read())).convert("RGB")


def compute_clip_score_from_path(image_path, target_letter):
    """Compute CLIP similarity and a visual score (0-100) for the provided letter.

    Returns a dict: {"clip_similarity": float, "visual_score": float, "feedback": str}
    Raises RuntimeError on failure.
    """
    # ensure model loaded (raises on failure)
    ensure_clip_loaded()
    # use predict_letter_with_clip to get a raw similarity for the best-matching letter
    pred_letter, confidence, raw_sim = predict_letter_with_clip(image_path)
    # map raw_sim (-1..1) to 0..100 visual score
    visual_score = max(0.0, min(100.0, (raw_sim + 1.0) * 50.0))
    if visual_score < 40:
        feedback = "Letter formation is unclear. Practice basic strokes."
    elif visual_score < 70:
        feedback = "Letter is recognizable but could be neater. Focus on consistent strokes."
    else:
        feedback = "Good formation! Letter shape is clear and consistent."
    return {"clip_similarity": round(raw_sim, 4), "visual_score": round(visual_score, 2), "feedback": feedback}


@clip_bp.route("/validate", methods=["POST"])
def clip_validate():
    data = request.json or {}
    image_b64 = data.get("image_b64")
    target = data.get("target_letter", "?")

    if not image_b64:
        return jsonify({"msg": "error", "error": "image_b64 is required"}), 400

    # decode and save to a temp file path
    try:
        image_data = image_b64.split(",")[1] if "," in image_b64 else image_b64
        img_bytes = base64.b64decode(image_data)
        tmp_path = os.path.join("uploads", f"clip_{int(__import__('time').time())}.png")
        os.makedirs("uploads", exist_ok=True)
        with open(tmp_path, "wb") as f:
            f.write(img_bytes)
    except Exception as e:
        return jsonify({"msg": "error", "error": f"failed to decode image: {e}"}), 500

    try:
        result = compute_clip_score_from_path(tmp_path, target)
        return jsonify({"msg": "ok", "result": result})
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        return jsonify({"msg": "error", "error": str(e), "traceback": tb}), 500


def compute_clip_letter_prediction(image_path):
    """Predict the most likely letter A-Z for a handwritten image using CLIP.

    Returns a dict: {"predicted_letter": "A", "confidence": 0.87}
    or None if CLIP isn't available.
    """
    # Use helper which raises on failure
    try:
        ensure_clip_loaded()
        pred_letter, confidence, raw_sim = predict_letter_with_clip(image_path)
        return {"predicted_letter": pred_letter, "confidence": confidence, "raw_similarity": raw_sim}
    except Exception as e:
        raise


def warmup_clip():
    """Load model and run a tiny encode to warm up weights and JIT paths."""
    try:
        # ensure helper loads model
        ensure_clip_loaded()
        return True
    except Exception as e:
        print(f"warmup_clip failed: {e}")
        return False


@clip_bp.route('/status', methods=['GET'])
def clip_status():
    """Return CLIP availability and basic info for diagnostics."""
    try:
        try:
            ensure_clip_loaded()
            info = {'available': True, 'device': 'cpu', 'preprocess_callable': True}
        except Exception as e:
            info = {'available': False, 'device': None, 'preprocess_callable': False, 'error': str(e)}
        return jsonify({'msg': 'ok', 'clip': info})
    except Exception as e:
        return jsonify({'msg': 'error', 'error': str(e)}), 500


@clip_bp.route('/reload', methods=['POST'])
def clip_reload():
    """Force re-attempt to load CLIP and warm up. Useful if imports previously failed."""
    try:
        # Attempt to ensure clip is loaded
        available = False
        warmed = False
        try:
            ensure_clip_loaded()
            warmed = True
            available = True
        except Exception as e:
            available = False
            warmed = False
            import traceback
            tb = traceback.format_exc()
            return jsonify({'msg': 'error', 'error': str(e), 'traceback': tb}), 500
        return jsonify({'msg': 'ok', 'available': available, 'warmed': warmed})
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        return jsonify({'msg': 'error', 'error': str(e), 'traceback': tb}), 500

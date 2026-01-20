# smartboard-backend/clip_loader.py

import torch
import open_clip

# 🔴 names expected by OLD backend
_model = None
_preprocess = None
_device = "cpu"


def ensure_clip_loaded():
    global _model, _preprocess

    if _model is not None:
        return True

    try:
        model, _, preprocess = open_clip.create_model_and_transforms(
            model_name="ViT-B-32",
            pretrained="openai",
            device=_device
        )
        model.eval()

        _model = model
        _preprocess = preprocess

        print("[CLIP] Loaded successfully (ViT-B-32, CPU)")
        return True

    except Exception as e:
        print("[CLIP] Failed to load:", e)
        return False


def get_clip():
    if _model is None:
        ensure_clip_loaded()
    return _model, _preprocess


# Backwards-compatible wrapper functions expected by legacy code
import numpy as _np
from PIL import Image as _Image
import cv2 as _cv2


def _ensure_model_or_raise():
    if _model is None:
        if not ensure_clip_loaded():
            raise RuntimeError("CLIP not loaded")


def compute_clip_similarity(image, text: str) -> float:
    """Compute CLIP cosine similarity between an image and text.

    Accepts a PIL Image or a NumPy array (OpenCV BGR). Returns a float similarity.
    Raises RuntimeError if CLIP not loaded.
    """
    _ensure_model_or_raise()

    model, preprocess = _model, _preprocess

    # Normalize image to PIL.Image
    if isinstance(image, _np.ndarray):
        # assume OpenCV BGR uint8
        try:
            img_rgb = _cv2.cvtColor(image, _cv2.COLOR_BGR2RGB)
        except Exception:
            # fallback: treat as already RGB
            img_rgb = image
        pil_img = _Image.fromarray(img_rgb)
    elif isinstance(image, _Image.Image):
        pil_img = image
    else:
        raise ValueError("Unsupported image type")

    # Text tokenization via open_clip
    text_tokens = open_clip.tokenize([text]).to(_device)

    with torch.no_grad():
        img_t = preprocess(pil_img).unsqueeze(0).to(_device)
        img_emb = model.encode_image(img_t)
        img_emb = img_emb / img_emb.norm(dim=-1, keepdim=True)

        txt_emb = model.encode_text(text_tokens)
        txt_emb = txt_emb / txt_emb.norm(dim=-1, keepdim=True)

        # compute cosine similarity
        sim = float((img_emb @ txt_emb.T).cpu().numpy().squeeze())

    return sim


def predict_letter_with_clip(image, candidates=None) -> dict:
    """Predict a letter A-Z using CLIP image-text similarity.

    - `image`: PIL Image or NumPy (OpenCV BGR)
    - `candidates`: iterable of candidate strings; if None, uses A-Z

    Returns dict with keys: predicted, confidence, scores
    """
    _ensure_model_or_raise()

    if candidates is None:
        candidates = [chr(i) for i in range(65, 91)]  # A-Z

    # Normalize image to PIL.Image
    if isinstance(image, _np.ndarray):
        try:
            img_rgb = _cv2.cvtColor(image, _cv2.COLOR_BGR2RGB)
        except Exception:
            img_rgb = image
        pil_img = _Image.fromarray(img_rgb)
    elif isinstance(image, _Image.Image):
        pil_img = image
    else:
        raise ValueError("Unsupported image type")

    model, preprocess = _model, _preprocess

    # Prepare image tensor
    with torch.no_grad():
        img_t = preprocess(pil_img).unsqueeze(0).to(_device)
        img_emb = model.encode_image(img_t)
        img_emb = img_emb / img_emb.norm(dim=-1, keepdim=True)

    # Tokenize candidate texts
    texts = [str(c) for c in candidates]
    text_tokens = open_clip.tokenize(texts).to(_device)

    with torch.no_grad():
        txt_emb = model.encode_text(text_tokens)
        txt_emb = txt_emb / txt_emb.norm(dim=-1, keepdim=True)

    # compute similarities
    sims = (img_emb @ txt_emb.T).cpu().numpy().squeeze()

    scores = {texts[i]: float(sims[i]) for i in range(len(texts))}

    # pick best
    best_idx = int(_np.argmax(sims))
    best_letter = texts[best_idx]
    confidence = float(sims[best_idx])

    return {"predicted": best_letter, "confidence": confidence, "scores": scores}

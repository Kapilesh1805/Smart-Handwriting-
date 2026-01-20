"""Template cache: loads template images and text embeddings at startup."""
from PIL import Image
import os
from typing import Dict
import torch
from clip_engine.clip_loader import load_clip
from .geometry import image_from_b64

TEMPLATE_CACHE = {
    "letters": {},
    "digits": {},
}


def _safe_open(path):
    try:
        return Image.open(path).convert("RGB")
    except Exception:
        return None


def init_template_cache(static_root: str = None):
    """Load templates and text embeddings into memory.

    static_root defaults to project-relative `static/`.
    This function calls `load_clip()` and will raise if CLIP fails.
    """
    # Ensure CLIP loaded
    model, preprocess, tokenizer = load_clip()

    base = static_root or os.path.join(os.path.dirname(__file__), "..", "static")
    base = os.path.abspath(base)

    # Precompute text embeddings for letters A-Z and digits 0-9
    letters = [chr(ord('A') + i) for i in range(26)]
    digits = [str(i) for i in range(10)]

    with torch.no_grad():
        for L in letters:
            txt_tokens = tokenizer(L)
            txt_emb = model.encode_text(txt_tokens)
            txt_emb = txt_emb / txt_emb.norm(dim=-1, keepdim=True)
            TEMPLATE_CACHE["letters"][L] = {"text": txt_emb, "images": []}

        for D in digits:
            txt_tokens = tokenizer(D)
            txt_emb = model.encode_text(txt_tokens)
            txt_emb = txt_emb / txt_emb.norm(dim=-1, keepdim=True)
            TEMPLATE_CACHE["digits"][D] = {"text": txt_emb, "images": []}

    # Load image templates from static/letters/<A>/uppercase.png etc.
    for L in letters:
        folder = os.path.join(base, "letters", L)
        if os.path.isdir(folder):
            for fname in ("uppercase.png", "lowercase.png", "handwritten.png"):
                p = os.path.join(folder, fname)
                img = _safe_open(p)
                if img is not None:
                    img_t = preprocess(img).unsqueeze(0)
                    with torch.no_grad():
                        emb = model.encode_image(img_t)
                        emb = emb / emb.norm(dim=-1, keepdim=True)
                    TEMPLATE_CACHE["letters"][L]["images"].append(emb)

    for D in digits:
        folder = os.path.join(base, "digits", D)
        if os.path.isdir(folder):
            for fname in ("digital.png", "handwritten.png"):
                p = os.path.join(folder, fname)
                img = _safe_open(p)
                if img is not None:
                    img_t = preprocess(img).unsqueeze(0)
                    with torch.no_grad():
                        emb = model.encode_image(img_t)
                        emb = emb / emb.norm(dim=-1, keepdim=True)
                    TEMPLATE_CACHE["digits"][D]["images"].append(emb)

    print(f"[TEMPLATE] Loaded templates from {base}", flush=True)
    return TEMPLATE_CACHE

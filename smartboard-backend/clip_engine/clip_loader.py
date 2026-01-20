"""
CLIP Loader - Single loader for handwriting recognition.

This is the ONLY place where CLIP is loaded.
- Loads once at startup
- Cached in memory
- Used by all pipelines
- No fallback; crash if fails
"""

import threading
import torch
import open_clip
from typing import Tuple, Optional

# Global state (thread-safe)
_clip_lock = threading.Lock()
_clip_model = None
_clip_preprocess = None
_clip_tokenizer = None
_clip_loaded = False
_clip_error = None


def load_clip() -> Tuple:
    """
    Load CLIP ViT-B-32 model exactly once.
    
    Returns:
        (model, preprocess, tokenizer) tuple
        
    Raises:
        RuntimeError if loading fails
    """
    global _clip_model, _clip_preprocess, _clip_tokenizer, _clip_loaded, _clip_error
    
    if _clip_loaded:
        if _clip_error:
            raise RuntimeError(f"CLIP load failed earlier: {_clip_error}")
        return _clip_model, _clip_preprocess, _clip_tokenizer
    
    with _clip_lock:
        # Double-check after lock
        if _clip_loaded:
            if _clip_error:
                raise RuntimeError(f"CLIP load failed earlier: {_clip_error}")
            return _clip_model, _clip_preprocess, _clip_tokenizer
        
        try:
            print("[CLIP] Loading ViT-B-32 from OpenAI pretrained...", flush=True)
            
            # CORRECT unpacking: model, _, preprocess
            model, _, preprocess = open_clip.create_model_and_transforms(
                "ViT-B-32",
                pretrained="openai"
            )
            
            # Move to CPU and set eval mode
            device = "cpu"
            model = model.to(device)
            model.eval()
            
            # Tokenizer for text embeddings
            tokenizer = open_clip.get_tokenizer("ViT-B-32")
            
            # Cache globally
            _clip_model = model
            _clip_preprocess = preprocess
            _clip_tokenizer = tokenizer
            _clip_loaded = True
            _clip_error = None
            
            print(f"[CLIP] Loaded successfully (ViT-B-32, CPU, {device})", flush=True)
            return model, preprocess, tokenizer
            
        except Exception as e:
            _clip_loaded = True
            _clip_error = str(e)
            print(f"[CLIP] LOAD FAILED: {e}", flush=True)
            raise RuntimeError(f"CLIP engine failed to load: {e}")


def get_clip() -> Tuple:
    """
    Get cached CLIP model or load it.
    
    Returns:
        (model, preprocess, tokenizer) tuple
        
    Raises:
        RuntimeError if CLIP is not available
    """
    if not _clip_loaded:
        return load_clip()
    
    if _clip_error:
        raise RuntimeError(f"CLIP load failed: {_clip_error}")
    
    return _clip_model, _clip_preprocess, _clip_tokenizer


def is_loaded() -> bool:
    """Check if CLIP is loaded and healthy."""
    return _clip_loaded and _clip_error is None


def embed_text(text: str) -> torch.Tensor:
    """
    Embed a single text string using CLIP.
    
    Args:
        text: Text to embed
        
    Returns:
        Embedding tensor (normalized)
    """
    model, _, tokenizer = get_clip()
    
    with torch.no_grad():
        text_tokens = tokenizer(text)
        text_embedding = model(text_tokens)
        text_embedding = text_embedding / text_embedding.norm(dim=-1, keepdim=True)
    
    return text_embedding


def embed_image(image_tensor: torch.Tensor) -> torch.Tensor:
    """
    Embed an image tensor using CLIP.
    
    Args:
        image_tensor: Image tensor (preprocessed)
        
    Returns:
        Embedding tensor (normalized)
    """
    model, _, _ = get_clip()
    
    with torch.no_grad():
        image_embedding = model(image_tensor)
        image_embedding = image_embedding / image_embedding.norm(dim=-1, keepdim=True)
    
    return image_embedding


def similarity(text_embedding: torch.Tensor, image_embedding: torch.Tensor) -> float:
    """
    Compute cosine similarity between text and image embeddings.
    
    Args:
        text_embedding: Text embedding
        image_embedding: Image embedding
        
    Returns:
        Similarity score (0-1)
    """
    # Cosine similarity for normalized embeddings = dot product
    sim = (text_embedding @ image_embedding.T).item()
    # Clamp to [0, 1]
    return max(0.0, min(1.0, float(sim)))


# ============================================================================
# High-level helper functions for compatibility with legacy code
# ============================================================================

import numpy as _np
from PIL import Image as _Image
import cv2 as _cv2


def ensure_clip_loaded():
    """
    Ensure CLIP is loaded. Returns True if successful.
    
    For compatibility with old code that checks the return value.
    """
    try:
        load_clip()
        return True
    except RuntimeError:
        return False


def compute_clip_similarity(image, text: str) -> float:
    """
    Compute CLIP cosine similarity between an image and text.
    
    Accepts a PIL Image or a NumPy array (OpenCV BGR).
    Returns a float similarity score.
    Raises RuntimeError if CLIP not loaded.
    """
    model, preprocess, tokenizer = get_clip()
    
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
    
    # Preprocess and embed image
    with torch.no_grad():
        img_t = preprocess(pil_img).unsqueeze(0)
        img_emb = model.encode_image(img_t)
        img_emb = img_emb / img_emb.norm(dim=-1, keepdim=True)
    
    # Tokenize and embed text
    with torch.no_grad():
        text_tokens = tokenizer([text])
        text_emb = model.encode_text(text_tokens)
        text_emb = text_emb / text_emb.norm(dim=-1, keepdim=True)
    
    # Compute cosine similarity
    sim = float((img_emb @ text_emb.T).squeeze().item())
    
    return sim


def predict_letter_with_clip(image, candidates=None) -> dict:
    """
    Predict a letter A-Z using CLIP image-text similarity.
    
    Args:
        image: PIL Image or NumPy (OpenCV BGR)
        candidates: iterable of candidate strings; if None, uses A-Z
    
    Returns:
        dict with keys: predicted, confidence, scores
    """
    model, preprocess, tokenizer = get_clip()
    
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
    
    # Preprocess and embed image
    with torch.no_grad():
        img_t = preprocess(pil_img).unsqueeze(0)
        img_emb = model.encode_image(img_t)
        img_emb = img_emb / img_emb.norm(dim=-1, keepdim=True)
    
    # Tokenize and embed all candidates
    texts = [str(c) for c in candidates]
    with torch.no_grad():
        text_tokens = tokenizer(texts)
        text_emb = model.encode_text(text_tokens)
        text_emb = text_emb / text_emb.norm(dim=-1, keepdim=True)
    
    # Compute similarities
    sims = (img_emb @ text_emb.T).squeeze().cpu().numpy()
    
    # Handle both single and batch results
    if sims.ndim == 0:
        sims = _np.array([sims.item()])
    
    scores = {texts[i]: float(sims[i]) for i in range(len(texts))}
    
    # Pick best
    best_idx = int(_np.argmax(sims))
    best_letter = texts[best_idx]
    confidence = float(sims[best_idx])
    
    return {"predicted": best_letter, "confidence": confidence, "scores": scores}

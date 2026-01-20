"""CLIP Engine package - Single loader for handwriting recognition."""

from .clip_loader import (
    load_clip,
    get_clip,
    is_loaded,
    embed_text,
    embed_image,
    similarity,
    ensure_clip_loaded,
    compute_clip_similarity,
    predict_letter_with_clip,
)

__all__ = [
    'load_clip',
    'get_clip',
    'is_loaded',
    'embed_text',
    'embed_image',
    'similarity',
    'ensure_clip_loaded',
    'compute_clip_similarity',
    'predict_letter_with_clip',
]

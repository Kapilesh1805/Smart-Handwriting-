from PIL import Image
from typing import Tuple
from clip_engine import get_clip, embed_image, embed_text
import torch
import numpy as np
import logging

logger = logging.getLogger(__name__)


def image_to_embedding(pil_image: Image.Image) -> torch.Tensor:
    """
    Encode PIL image to CLIP embedding.
    """
    model, preprocess, _ = get_clip()
    img_t = preprocess(pil_image).unsqueeze(0)
    
    with torch.no_grad():
        emb = model.encode_image(img_t)
        emb = emb / emb.norm(dim=-1, keepdim=True)
    return emb


def text_to_embedding(text: str):
    model, _, tokenizer = get_clip()
    with torch.no_grad():
        tokens = tokenizer(text)
        emb = model.encode_text(tokens)
        emb = emb / emb.norm(dim=-1, keepdim=True)
    return emb

import logging
import cv2
from PIL import Image

from utils.image_decode import decode_base64_image
from .pipeline_common import image_to_embedding
from .geometry import extract_geometry, restrict_candidates_for
from .template_cache import TEMPLATE_CACHE

logger = logging.getLogger(__name__)

# Tuned for image ↔ image CLIP (handwriting)
CONFIDENCE_THRESHOLD_PRIMARY = 0.70
CONFIDENCE_THRESHOLD_TEMPLATE = 0.65


def analyze_letter(image_b64: str, expected_letter: str) -> dict:
    expected = expected_letter.strip().upper()

    # -------------------------------
    # 1️⃣ Decode image
    # -------------------------------
    try:
        image = decode_base64_image(image_b64)
    except Exception as e:
        logger.error("[ALPHABET] Image decode failed: %s", e)
        return {
            "letter": "?",
            "confidence": 0.0,
            "is_correct": False,
            "message": "Bad image"
        }

    logger.info(
        "[IMAGE OK] shape=%s mean=%.2f std=%.2f",
        image.shape, image.mean(), image.std()
    )

    # Convert for CLIP
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(image_rgb)

    # -------------------------------
    # 2️⃣ Geometry (soft restriction)
    # -------------------------------
    try:
        geom = extract_geometry(image)
    except Exception as e:
        logger.warning("[ALPHABET] Geometry failed: %s", e)
        geom = {}

    restricted = restrict_candidates_for(expected)

    # ⚠️ NEVER drop expected letter
    if restricted and expected in restricted:
        candidates = restricted
    else:
        candidates = list(TEMPLATE_CACHE["letters"].keys())

    logger.info("[ALPHABET] Candidates: %s", candidates)

    # -------------------------------
    # 3️⃣ Image embedding (ONCE)
    # -------------------------------
    try:
        img_emb = image_to_embedding(pil_img)  # (1, D)
    except Exception as e:
        logger.error("[ALPHABET] Embedding failed: %s", e)
        return {
            "letter": "?",
            "confidence": 0.0,
            "is_correct": False,
            "message": "Embedding failed"
        }

    # -------------------------------
    # 4️⃣ PRIMARY: Image ↔ Image CLIP
    # -------------------------------
    scores = []

    for c in candidates:
        templates = TEMPLATE_CACHE["letters"].get(c, {}).get("images", [])
        if not templates:
            continue

        s = 0.0
        for t_emb in templates:
            s += float((img_emb @ t_emb.T).item())

        s /= len(templates)
        scores.append((c, s))

    scores.sort(key=lambda x: x[1], reverse=True)

    # Safety guard
    if not scores:
        logger.warning("[ALPHABET] No valid template scores")
        return {
            "letter": "?",
            "confidence": 0.0,
            "is_correct": False,
            "message": "Incorrect Letter"
        }

    top_char, top_score = scores[0]

    logger.info(
        "[ALPHABET] Image scores (top5): %s",
        [(c, round(s, 3)) for c, s in scores[:5]]
    )

    # -------------------------------
    # 5️⃣ Early accept
    # -------------------------------
    if top_char == expected and top_score >= CONFIDENCE_THRESHOLD_PRIMARY:
        return {
            "letter": top_char,
            "confidence": float(top_score),
            "is_correct": True,
            "message": "Correct Letter"
        }

    # -------------------------------
    # 6️⃣ Fallback: TEXT CLIP (rare)
    # -------------------------------
    fallback_scores = []

    for c, _ in scores[:5]:
        text_emb = TEMPLATE_CACHE["letters"][c].get("text")
        if text_emb is None:
            continue

        s = float((img_emb @ text_emb.T).item())
        fallback_scores.append((c, s))

    fallback_scores.sort(key=lambda x: x[1], reverse=True)

    if fallback_scores:
        fb_char, fb_score = fallback_scores[0]

        logger.info(
            "[ALPHABET] Text fallback scores: %s",
            [(c, round(s, 3)) for c, s in fallback_scores]
        )

        if fb_char == expected and fb_score >= CONFIDENCE_THRESHOLD_TEMPLATE:
            return {
                "letter": fb_char,
                "confidence": float(fb_score),
                "is_correct": True,
                "message": "Correct Letter"
            }

    # -------------------------------
    # 7️⃣ FINAL RESULT
    # -------------------------------
    return {
        "letter": top_char,
        "confidence": float(top_score),
        "is_correct": False,
        "message": "Incorrect Letter"
    }

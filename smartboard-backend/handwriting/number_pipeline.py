from utils.image_decode import decode_base64_image
from .pipeline_common import image_to_embedding
from .template_cache import TEMPLATE_CACHE
import cv2
from PIL import Image
import logging

logger = logging.getLogger(__name__)

CONFIDENCE_THRESHOLD_PRIMARY = 0.25
CONFIDENCE_THRESHOLD_TEMPLATE = 0.15


def analyze_number(image_b64: str, expected_digit: str) -> dict:
    expected = str(expected_digit).strip()
    try:
        image = decode_base64_image(image_b64)
    except Exception as e:
        logger.error("[NUMBER] Image decode failed: %s", e)
        print(f"[NUMBER] Image decode failed: {e}", flush=True)
        return {"digit": "?", "confidence": 0.0, "is_correct": False, "message": "Bad image"}

    # Log successful decode
    logger.info("[IMAGE OK] shape=%s mean=%.2f std=%.2f", image.shape, image.mean(), image.std())
    
    # Convert BGR to RGB for PIL compatibility
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(image_rgb)

    try:
        img_emb = image_to_embedding(pil_img)
    except Exception as e:
        logger.error("[NUMBER] Image embedding error: %s", e)
        print(f"[NUMBER] Image embedding error: {e}", flush=True)
        return {"digit": "?", "confidence": 0.0, "is_correct": False, "message": "Embedding failed"}

    candidates = list(TEMPLATE_CACHE["digits"].keys())

    scores = []
    for c in candidates:
        text_emb = TEMPLATE_CACHE["digits"][c]["text"]
        score = float((img_emb @ text_emb.T).item())
        scores.append((c, score))

    scores.sort(key=lambda x: x[1], reverse=True)
    
    # Guard against empty scores list
    if not scores:
        return {
            "digit": "?",
            "confidence": 0.0,
            "is_correct": False,
            "message": "❌ Incorrect Number",
            "debug": {
                "reason": "no_valid_candidates_after_filtering"
            }
        }
    
    top_char, top_score = scores[0]

    if top_char == expected and top_score >= CONFIDENCE_THRESHOLD_PRIMARY:
        return {"digit": top_char, "confidence": float(top_score), "is_correct": True, "message": "Correct Number"}

    # Template rerank
    shortlist = [c for c, _ in scores[:5]]
    best = ("?", 0.0)
    for cand in shortlist:
        imgs = TEMPLATE_CACHE["digits"][cand].get("images", [])
        if not imgs:
            s = dict(scores)[cand]
            if s > best[1]:
                best = (cand, s)
            continue
        s_avg = 0.0
        for t_emb in imgs:
            s_avg += float((img_emb @ t_emb.T).item())
        s_avg = s_avg / max(1, len(imgs))
        if s_avg > best[1]:
            best = (cand, s_avg)

    final_char, final_score = best
    is_correct = final_char == expected and final_score >= CONFIDENCE_THRESHOLD_TEMPLATE
    msg = "Correct Number" if is_correct else "Incorrect Number"

    return {"digit": final_char if final_char != "?" else top_char, "confidence": float(final_score), "is_correct": bool(is_correct), "message": msg}

"""
ML Service - CLIP-based inference for handwriting recognition.
Exposes HTTP endpoints for handwriting evaluation.
"""

from flask import Flask, request, jsonify
import logging
from handwriting_evaluator import evaluate_image_vs_image, evaluate_digit_image_vs_image

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy"}), 200

@app.route('/evaluate', methods=['POST'])
def evaluate_handwriting():
    """
    Evaluate handwriting against templates.

    Expected JSON:
    {
        "image_b64": "base64_encoded_image",
        "expected_char": "A",
        "char_type": "letter" or "digit"
    }
    """
    try:
        data = request.get_json()
        if not data or 'image_b64' not in data or 'expected_char' not in data:
            return jsonify({"error": "Missing image_b64 or expected_char"}), 400

        image_b64 = data['image_b64']
        expected_char = data['expected_char']
        char_type = data.get('char_type', 'letter')

        # Route to appropriate evaluator
        if char_type == 'digit':
            result = evaluate_digit_image_vs_image(image_b64, expected_char)
        else:
            result = evaluate_image_vs_image(image_b64, expected_char, char_type)

        return jsonify(result)

    except Exception as e:
        logger.error(f"Error evaluating handwriting: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/clip/image_similarity', methods=['POST'])
def image_similarity():
    """
    Compute CLIP similarity between two images.
    
    Expected JSON:
    {
        "image1": "base64_encoded_image1",
        "image2": "base64_encoded_image2"
    }
    """
    try:
        data = request.get_json()
        if not data or 'image1' not in data or 'image2' not in data:
            return jsonify({"error": "Missing image1 or image2"}), 400

        image1_b64 = data['image1']
        image2_b64 = data['image2']

        # Decode images
        from handwriting_evaluator import decode_base64_image, preprocess_image_once, embed_image_clip, ensure_clip_loaded
        
        # Ensure CLIP is loaded
        if not ensure_clip_loaded():
            return jsonify({"error": "CLIP model not available"}), 500
        
        img1_pil = decode_base64_image(image1_b64)
        img2_pil = decode_base64_image(image2_b64)
        
        # Preprocess and embed
        img1_processed = preprocess_image_once(img1_pil)
        img2_processed = preprocess_image_once(img2_pil)
        
        emb1 = embed_image_clip(img1_processed)
        emb2 = embed_image_clip(img2_processed)
        
        # Compute cosine similarity
        similarity = (emb1 @ emb2).item()
        
        return jsonify({"similarity": similarity})

    except Exception as e:
        logger.error(f"Error computing image similarity: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=7860)

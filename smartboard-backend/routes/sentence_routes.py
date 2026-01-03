from flask import Blueprint, request, jsonify
from database import sentences_col
from datetime import datetime

sentence_bp = Blueprint(
    "sentence_bp",
    __name__,
)

def get_sentence_by_difficulty(difficulty):
    easy = [
        "The cat runs.",
        "I like apples.",
        "The sun is hot."
    ]

    medium = [
        "The little boy is playing in the park.",
        "She likes to read books every day."
    ]

    hard = [
        "Although it was raining, the children continued playing outside.",
        "The teacher explained the lesson very clearly to the students."
    ]

    if difficulty == "easy":
        return easy[0]
    elif difficulty == "medium":
        return medium[0]
    elif difficulty == "hard":
        return hard[0]
    return None


@sentence_bp.route("/generate", methods=["GET"])
def generate_sentence():
    difficulty = request.args.get("difficulty", "").lower()
    child_id = request.args.get("child_id")

    if difficulty not in ["easy", "medium", "hard"]:
        return jsonify({"error": "Invalid difficulty"}), 400

    if not child_id:
        return jsonify({"error": "child_id required"}), 400

    sentence = get_sentence_by_difficulty(difficulty)

    sentence_doc = {
        "child_id": child_id,
        "sentence": sentence,
        "difficulty": difficulty,
        "created_at": datetime.utcnow()
    }

    result = sentences_col.insert_one(sentence_doc)

    return jsonify({
        "msg": "sentence_generated",
        "sentence_id": str(result.inserted_id),
        "sentence": sentence,
        "difficulty": difficulty
    })

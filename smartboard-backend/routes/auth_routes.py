from flask import Blueprint, request, jsonify
from database import users_col
from utils import create_token
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import datetime

auth_bp = Blueprint("auth", __name__, url_prefix="/auth")

@auth_bp.route("/register", methods=["POST"])
def register():
    try:
        data = request.json or {}
        email = data.get("email")
        password = data.get("password")
        name = data.get("name", "")
        
        if not email or not password:
            return jsonify({"msg": "error", "error": "Email and password required"}), 400
        
        # Check if email already exists
        existing_user = users_col.find_one({"email": email})
        if existing_user:
            return jsonify({"msg": "error", "error": "Email already registered. Please login instead."}), 409
        
        user = {
            "_id": str(uuid.uuid4()),
            "email": email,
            "name": name,
            "password": generate_password_hash(password),
            "created_at": datetime.datetime.utcnow()
        }
        users_col.insert_one(user)
        token = create_token(user["_id"])
        return jsonify({"msg": "registered", "token": token, "user_id": user["_id"], "name": user.get("name", "User")}), 201
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@auth_bp.route("/login", methods=["POST"])
def login():
    try:
        data = request.json or {}
        email = data.get("email")
        password = data.get("password")
        
        if not email or not password:
            return jsonify({"msg": "error", "error": "Email and password required"}), 400
        
        user = users_col.find_one({"email": email})
        if not user or not check_password_hash(user["password"], password):
            return jsonify({"msg": "error", "error": "Invalid email or password"}), 401
        
        token = create_token(user["_id"])
        return jsonify({"msg": "ok", "token": token, "user_id": user["_id"], "user_name": user.get("name", "User")}), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@auth_bp.route("/update_profile", methods=["PUT"])
def update_profile():
    """
    Updates therapist profile details.
    Accepts JSON:
    {
      "user_id": "...",
      "name": "New Name",
      "email": "newmail@example.com",
      "password": "newpass" (optional)
    }
    """
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        name = data.get("name")
        email = data.get("email")
        password = data.get("password")

        if not user_id:
            return jsonify({"msg": "error", "error": "user_id required"}), 400

        update_data = {}
        if name:
            update_data["name"] = name
        if email:
            update_data["email"] = email
        if password:
            update_data["password"] = generate_password_hash(password)

        if not update_data:
            return jsonify({"msg": "error", "error": "no fields to update"}), 400

        from database import users_col
        result = users_col.update_one({"_id": user_id}, {"$set": update_data})

        if result.modified_count > 0:
            return jsonify({"msg": "profile updated", "updated_fields": list(update_data.keys())})
        else:
            return jsonify({"msg": "no changes made"}), 200

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

# temporary in-memory store for reset tokens
reset_tokens = {}

@auth_bp.route("/forgot_password", methods=["POST"])
def forgot_password():
    """
    Expects: { "email": "user@example.com" }
    Returns a temporary reset token (in real case, email it)
    """
    try:
        data = request.json or {}
        email = data.get("email")

        if not email:
            return jsonify({"msg": "error", "error": "Email required"}), 400

        user = users_col.find_one({"email": email})
        if not user:
            return jsonify({"msg": "error", "error": "User not found"}), 404

        token = str(uuid.uuid4())
        reset_tokens[token] = {
            "user_id": str(user["_id"]),
            "expires_at": datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
        }

        # (in a real system, you'd email this token link)
        return jsonify({
            "msg": "reset token generated",
            "reset_token": token,
            "expires_in_minutes": 15
        })
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


@auth_bp.route("/reset_password", methods=["POST"])
def reset_password():
    """
    Expects: { "token": "<reset_token>", "new_password": "..." }
    """
    try:
        data = request.json or {}
        token = data.get("token")
        new_password = data.get("new_password")

        if not token or not new_password:
            return jsonify({"msg": "error", "error": "Token and new_password required"}), 400

        token_data = reset_tokens.get(token)
        if not token_data:
            return jsonify({"msg": "error", "error": "Invalid or expired token"}), 400

        if datetime.datetime.utcnow() > token_data["expires_at"]:
            del reset_tokens[token]
            return jsonify({"msg": "error", "error": "Token expired"}), 400

        user_id = token_data["user_id"]
        hashed_pw = generate_password_hash(new_password)
        users_col.update_one({"_id": user_id}, {"$set": {"password": hashed_pw}})

        # remove used token
        del reset_tokens[token]

        return jsonify({"msg": "password reset successful", "user_id": user_id})
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500
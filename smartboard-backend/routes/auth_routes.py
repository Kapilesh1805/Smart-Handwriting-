from flask import Blueprint, request, jsonify
from database import users_col
from helpers import create_token
from werkzeug.security import generate_password_hash, check_password_hash
import logging

logger = logging.getLogger(__name__)

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
    """Login endpoint with hardened error handling."""
    try:
        # Extract JSON safely
        data = request.json or {}
        email = data.get("email", "").strip() if data.get("email") else None
        password = data.get("password")

        # Validate input
        if not email or not password:
            logger.warning("[AUTH] Login attempt with missing email or password")
            return jsonify({
                "status": "error",
                "message": "Email and password required"
            }), 400

        # Look up user
        try:
            user = users_col.find_one({"email": email})
        except Exception as db_err:
            logger.error(f"[AUTH] Database error on user lookup: {db_err}")
            return jsonify({
                "status": "error",
                "message": "Server error: database unavailable"
            }), 500

        # Check user exists and password matches
        if not user:
            logger.warning(f"[AUTH] Login failed: user not found for email {email}")
            return jsonify({
                "status": "error",
                "message": "Invalid email or password"
            }), 401

        if not check_password_hash(user.get("password", ""), password):
            logger.warning(f"[AUTH] Login failed: password mismatch for user {email}")
            return jsonify({
                "status": "error",
                "message": "Invalid email or password"
            }), 401

        # Generate token
        try:
            token = create_token({"user_id": user["_id"]})
        except Exception as token_err:
            logger.error(f"[AUTH] Token generation failed: {token_err}")
            return jsonify({
                "status": "error",
                "message": "Failed to generate authentication token"
            }), 500

        # Success
        logger.info(f"[AUTH] Login successful for user {user['_id']}")
        return jsonify({
            "status": "success",
            "msg": "ok",
            "token": token,
            "user_id": user["_id"],
            "user_name": user.get("name", "User")
        }), 200

    except Exception as e:
        logger.error(f"[AUTH] Unexpected error in login handler: {e}", exc_info=True)
        return jsonify({
            "status": "error",
            "message": "Internal server error during login"
        }), 500

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
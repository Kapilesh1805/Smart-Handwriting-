from flask import Blueprint, request, jsonify
from database import children_col
from bson import ObjectId
import uuid
import datetime

child_bp = Blueprint("child", __name__, url_prefix="/children")

@child_bp.route("", methods=["GET"])
def get_children():
    """
    Get all children for the authenticated user.
    Expected header: Authorization: Bearer <token>
    """
    try:
        # Get user_id from request header or query param
        user_id = request.args.get("user_id") or request.headers.get("X-User-ID")
        
        if not user_id:
            return jsonify({"msg": "error", "error": "User ID required"}), 400
        
        # Fetch children for this user
        children = list(children_col.find({"user_id": user_id}))
        
        # Convert ObjectId to string for JSON serialization
        for child in children:
            if "_id" in child:
                child["_id"] = str(child["_id"])
        
        return jsonify({
            "msg": "children fetched",
            "children": children
        }), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@child_bp.route("", methods=["POST"])
def add_child():
    """
    Create a new child profile.
    Expected JSON:
    {
        "user_id": "...",
        "name": "John",
        "age": 7,
        "notes": "Optional notes"
    }
    """
    try:
        data = request.json or {}
        user_id = data.get("user_id")
        name = data.get("name")
        age = data.get("age")
        notes = data.get("notes", "")
        
        if not user_id:
            return jsonify({"msg": "error", "error": "User ID required"}), 400
        if not name:
            return jsonify({"msg": "error", "error": "Child name required"}), 400
        
        child = {
            "_id": str(uuid.uuid4()),
            "user_id": user_id,
            "name": name,
            "age": age,
            "notes": notes,
            "created_at": datetime.datetime.utcnow(),
            "last_session": None
        }
        
        children_col.insert_one(child)
        
        # Return clean response
        return jsonify({
            "msg": "child created",
            "child_id": child["_id"],
            "name": child["name"],
            "age": child["age"]
        }), 201
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@child_bp.route("/<child_id>", methods=["GET"])
def get_child(child_id):
    """
    Get a specific child by ID.
    """
    try:
        child = children_col.find_one({"_id": child_id})
        if not child:
            return jsonify({"msg": "error", "error": "Child not found"}), 404
        
        child["_id"] = str(child["_id"])
        return jsonify({
            "msg": "child fetched",
            "child": child
        }), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@child_bp.route("/<child_id>", methods=["PUT"])
def update_child(child_id):
    """
    Update a child's information.
    Expected JSON:
    {
        "name": "New Name",
        "age": 8,
        "notes": "Updated notes"
    }
    """
    try:
        data = request.json or {}
        update_fields = {}

        if "name" in data and data["name"]:
            update_fields["name"] = data["name"]
        if "age" in data:
            update_fields["age"] = data["age"]
        if "notes" in data:
            update_fields["notes"] = data["notes"]

        if not update_fields:
            return jsonify({"msg": "error", "error": "No valid fields to update"}), 400

        result = children_col.update_one(
            {"_id": child_id},
            {"$set": update_fields}
        )

        if result.modified_count > 0:
            return jsonify({
                "msg": "child updated",
                "child_id": child_id,
                "updated_fields": list(update_fields.keys())
            }), 200
        else:
            return jsonify({"msg": "no changes made or invalid ID"}), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


@child_bp.route("/<child_id>", methods=["DELETE"])
def delete_child(child_id):
    """
    Delete a child profile.
    """
    try:
        result = children_col.delete_one({"_id": child_id})

        if result.deleted_count > 0:
            return jsonify({
                "msg": "child deleted",
                "child_id": child_id
            }), 200
        else:
            return jsonify({"msg": "error", "error": "Child not found"}), 404
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

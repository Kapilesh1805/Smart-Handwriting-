from flask import Blueprint, request, jsonify
from database import db
import uuid
import datetime

notifications_col = db["notifications"]

notifications_bp = Blueprint("notifications", __name__, url_prefix="/notifications")

# 📬 Add a new notification/message
@notifications_bp.route("/add", methods=["POST"])
def add_notification():
    """
    Adds a motivational message or reminder.
    Expects JSON:
    {
      "title": "Daily Motivation",
      "message": "You automatically lose the chances you don't take."
    }
    """
    try:
        data = request.json or {}
        title = data.get("title", "Notification")
        message = data.get("message")

        if not message:
            return jsonify({"msg": "error", "error": "Message text required"}), 400

        notification = {
            "_id": str(uuid.uuid4()),
            "title": title,
            "message": message,
            "created_at": datetime.datetime.utcnow()
        }

        notifications_col.insert_one(notification)
        return jsonify({"msg": "notification added", "data": notification}), 201

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# 📄 Get all notifications/messages
@notifications_bp.route("/all", methods=["GET"])
def get_all_notifications():
    try:
        notifications = list(notifications_col.find().sort("created_at", -1))
        for n in notifications:
            n["_id"] = str(n["_id"])
        return jsonify({"msg": "success", "notifications": notifications}), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# ❌ Delete a notification
@notifications_bp.route("/delete/<notification_id>", methods=["DELETE"])
def delete_notification(notification_id):
    try:
        result = notifications_col.delete_one({"_id": notification_id})
        if result.deleted_count > 0:
            return jsonify({"msg": "notification deleted", "id": notification_id}), 200
        else:
            return jsonify({"msg": "no matching notification found"}), 404
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

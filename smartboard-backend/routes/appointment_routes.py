from flask import Blueprint, request, jsonify
from database import db
import uuid
import datetime

appointments_col = db["appointments"]

appointment_bp = Blueprint("appointment", __name__, url_prefix="/appointment")

# ➕ Add new appointment
@appointment_bp.route("/add", methods=["POST"])
def add_appointment():
    try:
        data = request.json or {}
        child_name = data.get("child_name")
        therapist_name = data.get("therapist_name")
        session_type = data.get("session_type")
        date = data.get("date")   # e.g. "2025-10-25"
        time = data.get("time")   # e.g. "16:00"

        if not all([child_name, therapist_name, session_type, date, time]):
            return jsonify({"msg": "error", "error": "Missing required fields"}), 400

        appointment = {
            "_id": str(uuid.uuid4()),
            "child_name": child_name,
            "therapist_name": therapist_name,
            "session_type": session_type,
            "date": date,
            "time": time,
            "status": "pending",  # pending / completed / missed
            "created_at": datetime.datetime.utcnow()
        }

        appointments_col.insert_one(appointment)
        return jsonify({"msg": "appointment added", "data": appointment}), 201

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# 📅 View all appointments
@appointment_bp.route("/all", methods=["GET"])
def get_all_appointments():
    try:
        print("🔍 Fetching all appointments...")
        appointments = list(appointments_col.find().sort("date", 1))
        print(f"📋 Found {len(appointments)} appointments")
        for a in appointments:
            a["_id"] = str(a["_id"])
        print(f"✅ Returning appointments: {appointments}")
        return jsonify({"msg": "success", "appointments": appointments}), 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"msg": "error", "error": str(e)}), 500


# 📆 View today’s appointments
@appointment_bp.route("/today", methods=["GET"])
def get_todays_appointments():
    try:
        today_str = datetime.datetime.utcnow().strftime("%Y-%m-%d")
        todays_appointments = list(appointments_col.find({"date": today_str}))
        for a in todays_appointments:
            a["_id"] = str(a["_id"])
        return jsonify({"msg": "success", "appointments": todays_appointments}), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@appointment_bp.route("/update_status", methods=["PUT"])
def update_status():
    """
    Updates appointment status.
    Expects JSON:
    {
      "appointment_id": "uuid",
      "status": "completed" | "pending" | "missed"
    }
    """
    try:
        data = request.json or {}
        appointment_id = data.get("appointment_id")
        status = data.get("status")

        if not appointment_id or not status:
            return jsonify({"msg": "error", "error": "appointment_id and status are required"}), 400

        if status not in ["completed", "pending", "missed"]:
            return jsonify({"msg": "error", "error": "invalid status value"}), 400

        from database import db
        appointments_col = db["appointments"]

        result = appointments_col.update_one(
            {"_id": appointment_id},
            {"$set": {"status": status}}
        )

        if result.modified_count > 0:
            return jsonify({"msg": "status updated", "appointment_id": appointment_id, "new_status": status})
        else:
            return jsonify({"msg": "no matching appointment or already same status"}), 200

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

@appointment_bp.route("/by_date", methods=["GET"])
def get_appointments_by_date():
    """
    Example: /appointment/by_date?date=2025-08-18
    Returns all appointments for that specific date.
    """
    try:
        date = request.args.get("date")
        if not date:
            return jsonify({"msg": "error", "error": "Date query parameter required"}), 400

        from database import appointments_col
        appointments = list(appointments_col.find({"date": date}))
        for a in appointments:
            a["_id"] = str(a["_id"])
        return jsonify({"msg": "success", "appointments": appointments}), 200
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500



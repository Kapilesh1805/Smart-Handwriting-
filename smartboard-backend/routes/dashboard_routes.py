from flask import Blueprint, jsonify
from database import children_col, sessions_col, reports_col
import datetime

dashboard_bp = Blueprint("dashboard", __name__, url_prefix="/dashboard")

@dashboard_bp.route("/summary", methods=["GET"])
def dashboard_summary():
    try:
        total_children = children_col.count_documents({})
        total_sessions = sessions_col.count_documents({})
        total_reports = reports_col.count_documents({})

        # Count today’s sessions (based on UTC)
        today = datetime.datetime.utcnow().date()
        start = datetime.datetime.combine(today, datetime.time.min)
        end = datetime.datetime.combine(today, datetime.time.max)
        todays_sessions = sessions_col.count_documents({"timestamp": {"$gte": start, "$lte": end}})

        summary = {
            "total_children": total_children,
            "total_sessions": total_sessions,
            "total_reports": total_reports,
            "todays_sessions": todays_sessions
        }

        return jsonify({"msg": "success", "data": summary})

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)})

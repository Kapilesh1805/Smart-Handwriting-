from flask import Blueprint, request, jsonify
from database import children_col, appointments_col, reports_col

search_bp = Blueprint("search", __name__, url_prefix="/search")

@search_bp.route("/", methods=["GET"])
def global_search():
    """
    Searches children, appointments, and reports by keyword.
    Example: /search?q=Jonathan
    """
    try:
        query = request.args.get("q", "").strip()
        if not query:
            return jsonify({"msg": "error", "error": "query param 'q' required"}), 400

        regex = {"$regex": query, "$options": "i"}

        # search children by name
        children_results = list(children_col.find({"name": regex}, {"_id": 1, "name": 1, "age": 1}))
        for c in children_results:
            c["_id"] = str(c["_id"])

        # search appointments by child or therapist
        appointments_results = list(appointments_col.find(
            {"$or": [{"child_name": regex}, {"therapist_name": regex}]},
            {"_id": 1, "child_name": 1, "therapist_name": 1, "session_type": 1, "date": 1, "time": 1}
        ))
        for a in appointments_results:
            a["_id"] = str(a["_id"])

        # search reports by child_id reference (if name known)
        reports_results = list(reports_col.find(
            {"child_id": {"$regex": query, "$options": "i"}},
            {"_id": 1, "child_id": 1, "summary": 1, "generated_at": 1}
        ))
        for r in reports_results:
            r["_id"] = str(r["_id"])

        return jsonify({
            "msg": "success",
            "query": query,
            "results": {
                "children": children_results,
                "appointments": appointments_results,
                "reports": reports_results
            }
        })
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

from flask import Blueprint, jsonify, send_file, request
from database import reports_col, children_col
from datetime import datetime
import os
import pdfkit
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText

# --------------------------------------------------
# Blueprint
# --------------------------------------------------
report_bp = Blueprint("report_bp", __name__, url_prefix="/report")


# --------------------------------------------------
# GET: Fetch all reports for a child (JSON)
# --------------------------------------------------
@report_bp.route("/child/<child_id>", methods=["GET"])
def get_child_reports(child_id):
    try:
        reports = list(
            reports_col.find(
                {"child_id": child_id},
                {"_id": 0}
            )
        )

        return jsonify({
            "msg": "reports_fetched",
            "count": len(reports),
            "data": reports
        })
    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# --------------------------------------------------
# GET: Export latest report as PDF
# --------------------------------------------------
@report_bp.route("/export/<child_id>", methods=["GET"])
def export_report(child_id):
    """
    Generates and downloads the latest PDF report for the child.
    """
    try:
        report = reports_col.find_one(
            {"child_id": child_id},
            sort=[("created_at", -1)]
        )

        child = children_col.find_one({"_id": child_id})

        if not report or not child:
            return jsonify({
                "msg": "error",
                "error": "No report or child data found"
            }), 404

        analysis = report.get("analysis", {})

        html_content = f"""
        <h2>FLOE - Handwriting Assessment Report</h2>
        <h3>Child Name: {child.get('name', 'N/A')}</h3>
        <p>Age: {child.get('age', 'N/A')} | Grade: {child.get('grade', 'N/A')}</p>
        <hr>
        <h4>Scores</h4>
        <p>Pressure: {analysis.get('pressure_score', 0)}</p>
        <p>Spacing: {analysis.get('spacing_score', 0)}</p>
        <p>Formation: {analysis.get('formation_score', 0)}</p>
        <p>Accuracy: {analysis.get('accuracy_score', 0)}</p>
        <p>Overall: {analysis.get('overall_score', 0)}</p>
        <hr>
        <p>Feedback: {analysis.get('feedback', 'N/A')}</p>
        <p>Generated At: {report.get('created_at')}</p>
        """

        os.makedirs("reports", exist_ok=True)
        file_name = f"report_{child_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}.pdf"
        output_path = os.path.join("reports", file_name)

        pdfkit.from_string(html_content, output_path)

        return send_file(output_path, as_attachment=True)

    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500


# --------------------------------------------------
# POST: Email latest report to parent
# --------------------------------------------------
@report_bp.route("/email/<child_id>", methods=["POST"])
def email_report(child_id):
    """
    Emails the latest report PDF to the parent's email.
    Expects JSON body:
    {
        "email": "parent@example.com"
    }
    """
    try:
        data = request.json or {}
        to_email = data.get("email")

        if not to_email:
            return jsonify({
                "msg": "error",
                "error": "Parent email required"
            }), 400

        report = reports_col.find_one(
            {"child_id": child_id},
            sort=[("created_at", -1)]
        )

        if not report:
            return jsonify({
                "msg": "error",
                "error": "No report found"
            }), 404

        os.makedirs("reports", exist_ok=True)
        pdf_path = f"reports/temp_{child_id}.pdf"

        pdf_content = f"""
        <h2>FLOE - Handwriting Report</h2>
        <p>{report.get('analysis')}</p>
        """

        pdfkit.from_string(pdf_content, pdf_path)

        # -------------------------------
        # Email Configuration (DEMO)
        # -------------------------------
        sender_email = "your_email@gmail.com"
        sender_password = "your_app_password"

        msg = MIMEMultipart()
        msg["From"] = sender_email
        msg["To"] = to_email
        msg["Subject"] = "FLOE - Handwriting Assessment Report"

        msg.attach(
            MIMEText(
                "Dear Parent,\n\nAttached is your child’s handwriting progress report.\n\nRegards,\nFLOE Team"
            )
        )

        with open(pdf_path, "rb") as f:
            part = MIMEApplication(f.read(), Name=os.path.basename(pdf_path))

        part["Content-Disposition"] = f'attachment; filename="{os.path.basename(pdf_path)}"'
        msg.attach(part)

        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)

        return jsonify({
             "msg": f"Report emailed successfully to {to_email}"
        })


    except Exception as e:
        return jsonify({"msg": "error", "error": str(e)}), 500

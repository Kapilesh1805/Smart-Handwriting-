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
# GET: Fetch aggregated report for a child (JSON)
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

        if not reports:
            return jsonify({
                "msg": "no_reports_found",
                "pressure_score": 0,
                "formation_score": 0,
                "accuracy_score": 0,
                "spacing_score": None,
                "sentence_formation_score": None
            })

        # Group reports by evaluation_mode
        grouped = {}
        for report in reports:
            mode = report.get("evaluation_mode", "alphabet")
            if mode not in grouped:
                grouped[mode] = []
            grouped[mode].append(report)

        # Aggregate scores by mode
        results = {
            "pressure_score": 0,
            "formation_score": 0,
            "accuracy_score": 0,
            "spacing_score": None,
            "sentence_formation_score": None
        }

        # Alphabet mode: accuracy, formation_score, pressure_score
        if "alphabet" in grouped:
            alphabet_reports = grouped["alphabet"]
            acc_total = 0
            acc_count = 0
            form_total = 0
            form_count = 0
            press_total = 0
            press_count = 0
            
            for r in alphabet_reports:
                if "accuracy" in r and r["accuracy"] is not None:
                    acc_total += r["accuracy"]
                    acc_count += 1
                analysis = r.get("analysis", {})
                if "formation_score" in analysis and analysis["formation_score"] is not None:
                    form_total += analysis["formation_score"]
                    form_count += 1
                if "pressure_score" in analysis and analysis["pressure_score"] is not None:
                    press_total += analysis["pressure_score"]
                    press_count += 1
            
            results["accuracy_score"] = acc_total / acc_count if acc_count > 0 else 0
            results["formation_score"] = form_total / form_count if form_count > 0 else 0
            results["pressure_score"] = press_total / press_count if press_count > 0 else 0

        # Sentence mode: accuracy as sentence_formation_score, pressure_score
        if "sentence" in grouped:
            sentence_reports = grouped["sentence"]
            sent_form_total = 0
            sent_form_count = 0
            sent_press_total = 0
            sent_press_count = 0
            
            for r in sentence_reports:
                if "accuracy" in r and r["accuracy"] is not None:
                    sent_form_total += r["accuracy"]
                    sent_form_count += 1
                analysis = r.get("analysis", {})
                if "pressure_score" in analysis and analysis["pressure_score"] is not None:
                    sent_press_total += analysis["pressure_score"]
                    sent_press_count += 1
            
            results["sentence_formation_score"] = sent_form_total / sent_form_count if sent_form_count > 0 else None
            # Update pressure_score if sentence has it (prefer prewriting, but use sentence if available)
            if sent_press_count > 0 and results["pressure_score"] == 0:
                results["pressure_score"] = sent_press_total / sent_press_count

        # Prewriting mode: pressure_score
        if "prewriting" in grouped:
            prewriting_reports = grouped["prewriting"]
            pre_press_total = 0
            pre_press_count = 0
            
            for r in prewriting_reports:
                analysis = r.get("analysis", {})
                if "pressure_score" in analysis and analysis["pressure_score"] is not None:
                    pre_press_total += analysis["pressure_score"]
                    pre_press_count += 1
            
            if pre_press_count > 0:
                results["pressure_score"] = pre_press_total / pre_press_count

        # Round scores
        for key in ["pressure_score", "formation_score", "accuracy_score"]:
            if results[key] != 0:
                results[key] = round(results[key], 1)

        # Get historical data for series (last 10 sessions per mode)
        series_data = {
            "pressure_series": [],
            "accuracy_series": [],
            "formation_series": [],
            "timestamps": []
        }

        # Collect all reports sorted by created_at descending
        all_reports = list(
            reports_col.find(
                {"child_id": child_id},
                {"_id": 0, "created_at": 1, "evaluation_mode": 1, "accuracy": 1, "analysis": 1}
            ).sort("created_at", -1).limit(50)  # Get last 50 for series
        )

        # Group by mode and take last 10 per mode
        mode_groups = {}
        for r in all_reports:
            mode = r.get("evaluation_mode", "alphabet")
            if mode not in mode_groups:
                mode_groups[mode] = []
            if len(mode_groups[mode]) < 10:
                mode_groups[mode].append(r)

        # Build series from alphabet mode (for accuracy and formation)
        if "alphabet" in mode_groups:
            for r in reversed(mode_groups["alphabet"]):  # Reverse to chronological order
                series_data["accuracy_series"].append(r.get("accuracy", 0))
                analysis = r.get("analysis", {})
                series_data["formation_series"].append(analysis.get("formation_score", 0))
                series_data["timestamps"].append(r.get("created_at", "").split("T")[0] if r.get("created_at") else "")

        # Build pressure series from prewriting or sentence
        pressure_sources = []
        if "prewriting" in mode_groups:
            pressure_sources.extend(mode_groups["prewriting"])
        if "sentence" in mode_groups:
            pressure_sources.extend(mode_groups["sentence"])
        
        # Sort by created_at and take last 10
        pressure_sources.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        for r in reversed(pressure_sources[:10]):
            analysis = r.get("analysis", {})
            pressure = analysis.get("pressure_score")
            if pressure is not None:
                series_data["pressure_series"].append(pressure)

        # Ensure all series have same length
        min_length = min(len(series_data["pressure_series"]), len(series_data["accuracy_series"]))
        series_data["pressure_series"] = series_data["pressure_series"][:min_length]
        series_data["accuracy_series"] = series_data["accuracy_series"][:min_length]
        series_data["formation_series"] = series_data["formation_series"][:min_length]
        series_data["timestamps"] = series_data["timestamps"][:min_length]

        return jsonify({
            "msg": "reports_aggregated",
            **results,
            **series_data
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

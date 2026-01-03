from flask import Flask, jsonify
from flask_cors import CORS
from routes.sentence_routes import sentence_bp
from routes.auth_routes import auth_bp
from routes.child_routes import child_bp
from routes.handwriting_routes import handwriting_bp
from routes.dashboard_routes import dashboard_bp
from ml_model import try_load_model
from config import UPLOAD_FOLDER
from routes.appointment_routes import appointment_bp
from routes.prewriting_routes import prewriting_bp
from routes.notifications_routes import notifications_bp
from routes.report_routes import report_bp
from routes.search_routes import search_bp
import os


def create_app():
    app = Flask(__name__)
    
    # Enable CORS for all routes
    CORS(app, origins="*", supports_credentials=True)

    # register all blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(child_bp)
    app.register_blueprint(handwriting_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(appointment_bp)
    app.register_blueprint(prewriting_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(search_bp)
    app.register_blueprint(sentence_bp, url_prefix="/sentence")
    app.register_blueprint(report_bp)


   

    @app.route("/")
    def home():
        return jsonify({"msg": "smartboard-backend running"})

    return app


if __name__ == "__main__":
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    try_load_model()
    app = create_app()
    app.run(host="0.0.0.0", port=5000, debug=True)



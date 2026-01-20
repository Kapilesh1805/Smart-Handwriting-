"""Flask app factory with clean separation of CLIP preload and app creation."""
from flask import Flask, jsonify
import importlib
import os
import sys
import traceback
import logging
import threading

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

logger = logging.getLogger(__name__)

# Add smartboard-backend to sys.path to enable package-safe imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import clip_state (single source of truth for CLIP readiness)
# This MUST be imported before any routes
import clip_state

# Import blueprints AFTER we verify dependencies exist
# (but BEFORE app creation to avoid import order issues)
from config import UPLOAD_FOLDER


def _assert_running_in_venv():
    """Enforce using the project's venv python for safety."""
    exe = sys.executable.lower()
    if '.venv' not in exe and 'scripts\\python.exe' not in exe:
        raise RuntimeError(
            f"Server must be started with the project's venv python "
            f"(e.g. & .\\.venv\\Scripts\\python.exe app.py). "
            f"Current python: {sys.executable}"
        )


def _verify_dependencies():
    """Verify torch and open_clip are installed. Fail fast if missing."""
    print("[STARTUP] Verifying dependencies...", flush=True)
    try:
        torch_spec = importlib.util.find_spec('torch')
        open_clip_spec = importlib.util.find_spec('open_clip')
        
        if not torch_spec:
            raise RuntimeError('torch is not installed')
        if not open_clip_spec:
            raise RuntimeError('open_clip is not installed')
        
        import torch
        import open_clip
        print(f"[OK] torch {torch.__version__} installed", flush=True)
        print(f"[OK] open_clip installed", flush=True)
        return True
    except Exception as e:
        print(f"[CRITICAL] Dependency check failed: {e}", flush=True)
        traceback.print_exc()
        raise


def _background_warmup():
    """Background thread: Load CLIP model and templates without blocking startup.
    
    When complete, sets clip_state.CLIP_READY = True (single source of truth).
    """
    try:
        logger.info("[WARMUP] Starting background CLIP initialization...")        
        from handwriting.simple_clip_evaluator import ensure_clip_loaded
        if ensure_clip_loaded():
            # CRITICAL: Set the single global readiness flag
            clip_state.set_ready()
            logger.info("[WARMUP] ✅ CLIP warmed up and ready. All subsequent requests will be fast.")
        else:
            logger.warning("[WARMUP] ❌ CLIP warm-up failed, will retry on first request")
    except Exception as e:
        logger.warning(f"[WARMUP] ❌ Background warm-up failed: {e}")
        import traceback
        traceback.print_exc()


def preload_models():
    """Preload CLIP model and template embeddings. Must complete before Flask app creation.
    
    This function:
    - Blocks until CLIP is loaded or fails
    - Loads all template embeddings for letters and digits
    - Prints progress to stdout
    - Raises RuntimeError if CLIP loading fails
    - Is called BEFORE create_app()
    """
    # This function intentionally no-ops under the lazy-loading design.
    # CLIP model and templates will be loaded lazily on the first handwriting
    # request. Calling this function is safe but will not attempt to import
    # or initialize heavy ML dependencies.
    print("[STARTUP] CLIP preload skipped (lazy-loading enabled)", flush=True)
    return True


def _check_handwritten_templates():
    """Check if handwritten letter templates exist and log guidance."""
    from pathlib import Path
    
    static_letters_dir = Path(__file__).parent / 'static' / 'letters'
    templates_exist = False
    
    try:
        for letter_dir in static_letters_dir.glob('[A-Z]'):
            handwritten_dir = letter_dir / 'handwritten'
            if handwritten_dir.exists():
                templates = list(handwritten_dir.glob('*.png'))
                if templates:
                    templates_exist = True
                    break
    except Exception as e:
        logger.warning(f"[TemplateInfo] Error checking templates: {e}")
    
    if not templates_exist:
        logger.info("=" * 80)
        logger.info("[TemplateInfo] Handwritten letter templates not found!")
        logger.info("[TemplateInfo]")
        logger.info("[TemplateInfo] To enable automatic handwritten letter recognition,")
        logger.info("[TemplateInfo] run the setup script from the project root:")
        logger.info("[TemplateInfo]")
        logger.info("[TemplateInfo]   python scripts/setup_handwritten_letters.py")
        logger.info("[TemplateInfo]")
        logger.info("[TemplateInfo] This will:")
        logger.info("[TemplateInfo]   - Download EMNIST handwritten letter dataset")
        logger.info("[TemplateInfo]   - Extract and process samples (A-Z, a-z)")
        logger.info("[TemplateInfo]   - Populate static/letters/{LETTER}/handwritten/")
        logger.info("[TemplateInfo]")
        logger.info("[TemplateInfo] The template fallback system will work better with")
        logger.info("[TemplateInfo] handwritten samples available.")
        logger.info("=" * 80)
    else:
        logger.info("[TemplateInfo] Handwritten letter templates found and ready!")


def create_app():
    """Create and configure Flask app. Called AFTER preload_models().
    
    At this point:
    - CLIP is already loaded and stored globally
    - Dependencies are verified
    - Upload folder exists
    
    This function only:
    - Creates Flask instance
    - Registers blueprints
    - Configures app
    
    NO side effects. NO CLIP loading here.
    """
    print("[STARTUP] Creating Flask app...", flush=True)
    app = Flask(__name__)

    # Import blueprints AFTER Flask is created
    # (they may reference Flask or app context)
    from routes.sentence_routes import sentence_bp
    from routes.auth_routes import auth_bp
    from routes.child_routes import child_bp
    from routes.handwriting_routes import handwriting_bp
    from routes.dashboard_routes import dashboard_bp
    from routes.clip_routes import clip_bp
    from routes.appointment_routes import appointment_bp
    from routes.prewriting_routes import prewriting_bp
    from routes.notifications_routes import notifications_bp
    from routes.report_routes import report_bp
    from routes.search_routes import search_bp

    # Register all blueprints
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(child_bp)
    app.register_blueprint(handwriting_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(clip_bp)
    app.register_blueprint(appointment_bp)
    app.register_blueprint(prewriting_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(search_bp)
    app.register_blueprint(sentence_bp, url_prefix="/sentence")
    app.register_blueprint(report_bp)

    # Skip eager CLIP-first pipeline cache initialization to keep startup fast.
    logger.info("[Cache] Skipping CLIP-first pipeline cache initialization (lazy-loading enabled)")
    
    # Start background warm-up thread (non-blocking)
    warmup_thread = threading.Thread(target=_background_warmup, daemon=True)
    warmup_thread.start()
    logger.info("[WARMUP] Background CLIP warm-up thread started (non-blocking)")

    @app.route("/")
    def home():
        return jsonify({"msg": "smartboard-backend running"})

    @app.route("/debug/python")
    def debug_python():
        try:
            torch_spec = importlib.util.find_spec('torch')
            clip_spec = importlib.util.find_spec('clip')
            return jsonify({
                "python_executable": sys.executable,
                "torch_installed": bool(torch_spec),
                "clip_installed": bool(clip_spec),
            })
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    print("[OK] Flask app created successfully", flush=True)
    
    # Expose warm-up status for health checks
    @app.route("/warmup-status", methods=["GET"])
    def warmup_status():
        is_ready = clip_state.is_ready()
        return jsonify({"warmup_complete": is_ready}), 200
    
    return app





if __name__ == "__main__":
    """STRICT STARTUP SEQUENCE - NO DEVIATIONS
    
    Order is critical:
    1. Verify dependencies (torch, open_clip)
    2. Verify venv
    3. Create upload folder
    4. Preload CLIP (blocking, must complete)
    5. Assert CLIP loaded successfully
    6. Create Flask app
    7. Register routes
    8. Start app.run()
    
    If ANY step fails → crash immediately (fail-fast)
    """
    try:
        # Step 1: Create upload folder
        print("[STARTUP] Starting Flask app initialization...", flush=True)
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        print("[STARTUP] Upload folder created", flush=True)
        
        # Step 2: Verify venv
        print(f"[STARTUP] Python executable: {sys.executable}", flush=True)
        print(f"[STARTUP] Sys.path[0]: {sys.path[0]}", flush=True)
        try:
            _assert_running_in_venv()
        except Exception as e:
            print(f"[STARTUP] WARNING: {e}")
            # Not fatal, but warn user
        
        # Step 3: Skip heavy dependency checks and eager CLIP preload to start fast.
        # CLIP will be loaded lazily on first handwriting request.
        print("[STARTUP] Skipping eager CLIP preload; model loads lazily on first request", flush=True)
        
        # Step 6: Check templates (non-fatal)
        print("[STARTUP] Checking for handwritten templates...", flush=True)
        try:
            _check_handwritten_templates()
        except Exception as e:
            logger.warning(f"[TemplateInfo] Template check error: {e}")
        
        # Step 7: CREATE FLASK APP
        print("\n" + "="*80, flush=True)
        print("[STARTUP] Creating Flask app and registering routes...", flush=True)
        print("="*80, flush=True)
        app = create_app()
        
        # Step 8: START SERVER
        print(f"[INFO] Starting server on http://0.0.0.0:5000", flush=True)
        print("="*80 + "\n", flush=True)
        print("[STARTUP] Server starting...", flush=True)
        
        # CRITICAL: use_reloader=False to prevent double-loading CLIP
        app.run(
            host="0.0.0.0",
            port=5000,
            debug=False,
            use_reloader=False,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\n[SHUTDOWN] Server interrupted by user", flush=True)
        sys.exit(0)
    except Exception as e:
        print(f"\n[FATAL] Startup failed: {e}", flush=True)
        traceback.print_exc()
        sys.exit(1)






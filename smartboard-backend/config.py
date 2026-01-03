import os

MONGO_URI = "mongodb+srv://admin:admin123@cluster0.duenbjj.mongodb.net/smartboard?retryWrites=true&w=majority"
DB_NAME = "smartboard"
JWT_SECRET = os.getenv("JWT_SECRET", "replace_this_with_a_secret")
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), "uploads")
ML_MODEL_PATH = os.path.join(os.path.dirname(__file__), "ml", "model.h5")   # ✅ this is the missing one

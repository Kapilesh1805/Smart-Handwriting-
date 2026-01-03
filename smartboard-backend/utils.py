import os, uuid, base64
from werkzeug.utils import secure_filename
from config import UPLOAD_FOLDER
import jwt
from config import JWT_SECRET
from datetime import datetime, timedelta

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def save_base64_image(b64_string, prefix="img"):
    header, data = (b64_string.split(",",1) if "," in b64_string else (None, b64_string))
    ext = "png"
    filename = f"{prefix}_{uuid.uuid4().hex}.{ext}"
    path = os.path.join(UPLOAD_FOLDER, secure_filename(filename))
    with open(path, "wb") as f:
        f.write(base64.b64decode(data))
    return path

def create_token(user_id):
    payload = {"user_id": str(user_id), "exp": datetime.utcnow() + timedelta(hours=12)}
    token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
    return token

def verify_token(token):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload.get("user_id")
    except Exception as e:
        return None

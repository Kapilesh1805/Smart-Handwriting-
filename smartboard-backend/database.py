from pymongo import MongoClient
from config import MONGO_URI, DB_NAME

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

users_col = db["users"]
children_col = db["children"]
sessions_col = db["sessions"]
appointments_col = db["appointments"]
notifications_col = db["notifications"]
reports_col = db["reports"]
sentences_col = db["sentences"]

import os

from dotenv import load_dotenv

load_dotenv()

APP_PORT = int(os.getenv("APP_PORT", "8000"))

EMAIL_HOST = os.getenv("EMAIL_HOST")
TOKEN_SECRET_KEY = os.getenv("TOKEN_SECRET_KEY")

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PWD = os.getenv("DB_PWD")

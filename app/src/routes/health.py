from flask import Blueprint, jsonify
from app import db
from sqlalchemy import text

health_bp = Blueprint("health", __name__)


@health_bp.route("/health")
def health():
    status = {"status": "ok", "components": {}}

    try:
        db.session.execute(text("SELECT 1"))
        status["components"]["database"] = "ok"
    except Exception as e:
        status["components"]["database"] = f"error: {e}"
        status["status"] = "degraded"

    code = 200 if status["status"] == "ok" else 503
    return jsonify(status), code

import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from prometheus_flask_exporter import PrometheusMetrics
import structlog

db = SQLAlchemy()
login_manager = LoginManager()


def create_app():
    app = Flask(__name__)
    app.config.from_object("config.Config")

    db.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = "auth.login"

    PrometheusMetrics(app, path="/metrics")

    _configure_logging()

    from routes.auth import auth_bp
    from routes.tickets import tickets_bp
    from routes.health import health_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(tickets_bp, url_prefix="/tickets")
    app.register_blueprint(health_bp)

    with app.app_context():
        db.create_all()

    return app


def _configure_logging():
    structlog.configure(
        processors=[
            structlog.stdlib.add_log_level,
            structlog.stdlib.add_logger_name,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
    )

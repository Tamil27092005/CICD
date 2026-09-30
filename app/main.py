"""Minimal Flask application used to demonstrate the CI/CD pipeline."""
import os
import platform
from datetime import datetime, timezone

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(
            message="CI/CD pipeline demo: Dockerized Python app",
            version=os.getenv("APP_VERSION", "dev"),
            environment=os.getenv("APP_ENV", "development"),
        )

    @app.get("/health")
    def health():
        return jsonify(status="healthy"), 200

    @app.get("/info")
    def info():
        return jsonify(
            hostname=platform.node(),
            python_version=platform.python_version(),
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

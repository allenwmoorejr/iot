"""Flask application entrypoint for the Raspberry Pi car dashboard."""

from __future__ import annotations

import logging
from typing import Any, Dict

from flask import Flask, jsonify, render_template

from .config import Config, load_config
from .data_providers import get_provider


LOGGER = logging.getLogger(__name__)


def create_app(config: Config | None = None) -> Flask:
    """Application factory used by Flask CLI and WSGI servers."""
    cfg = config or load_config()
    app = Flask(__name__, static_folder="static", template_folder="templates")
    app.config.update(cfg.flask_settings)
    app.config.setdefault("DASHBOARD_TITLE", cfg.dashboard_title)

    provider = get_provider(cfg.provider_name, cfg)
    LOGGER.info("Using data provider: %%s", provider.name)

    @app.route("/")
    def index() -> str:
        return render_template(
            "index.html",
            refresh_seconds=cfg.refresh_seconds,
            dashboard_title=cfg.dashboard_title,
        )

    @app.route("/api/dashboard")
    def dashboard() -> Any:
        payload: Dict[str, Any] = provider.get_dashboard_data()
        return jsonify(payload)

    @app.route("/api/health")
    def health() -> Any:
        return jsonify({"status": "ok", "provider": provider.name})

    @app.route("/api/provider")
    def provider_info() -> Any:
        return jsonify(provider.describe())

    return app


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    application = create_app()
    application.run(host="0.0.0.0", port=8000)

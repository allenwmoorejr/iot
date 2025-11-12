"""Configuration helpers for the car dashboard application."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Dict


DEFAULT_REFRESH_SECONDS = 3
DEFAULT_PROVIDER = "mock"
DEFAULT_TITLE = "Pi Dash"


@dataclass(slots=True)
class Config:
    provider_name: str = DEFAULT_PROVIDER
    refresh_seconds: int = DEFAULT_REFRESH_SECONDS
    dashboard_title: str = DEFAULT_TITLE
    flask_settings: Dict[str, object] = field(default_factory=dict)


ENV_MAPPING = {
    "CAR_DASH_PROVIDER": "provider_name",
    "CAR_DASH_REFRESH_SECONDS": "refresh_seconds",
    "CAR_DASH_TITLE": "dashboard_title",
}


def load_config() -> Config:
    cfg = Config()

    for env_var, attr in ENV_MAPPING.items():
        value = os.getenv(env_var)
        if value is None:
            continue
        if attr == "refresh_seconds":
            try:
                cfg.refresh_seconds = max(1, int(value))
            except ValueError:
                continue
        else:
            setattr(cfg, attr, value)

    secret_key = os.getenv("CAR_DASH_SECRET_KEY")
    if secret_key:
        cfg.flask_settings["SECRET_KEY"] = secret_key

    return cfg

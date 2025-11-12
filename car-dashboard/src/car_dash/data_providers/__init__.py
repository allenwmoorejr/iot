"""Registry for car dashboard data providers."""

from __future__ import annotations

from typing import Dict, Type

from ..config import Config
from .base import BaseDataProvider
from .mock import MockDataProvider

try:  # optional dependencies
    from .obd import OBDDataProvider
except RuntimeError:  # python-OBD missing during import
    OBDDataProvider = None  # type: ignore
except ImportError:  # pragma: no cover - module not available
    OBDDataProvider = None  # type: ignore

from .system import SystemDataProvider


PROVIDERS: Dict[str, Type[BaseDataProvider]] = {
    MockDataProvider.name: MockDataProvider,
    SystemDataProvider.name: SystemDataProvider,
}

if OBDDataProvider is not None:
    PROVIDERS[OBDDataProvider.name] = OBDDataProvider


def get_provider(name: str, config: Config) -> BaseDataProvider:
    provider_cls = PROVIDERS.get(name)
    if provider_cls is None:
        raise ValueError(f"Unknown provider '{name}'. Available: {list(PROVIDERS)}")
    return provider_cls(config)

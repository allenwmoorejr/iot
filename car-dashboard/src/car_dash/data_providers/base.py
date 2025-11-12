"""Base class for dashboard data providers."""

from __future__ import annotations

import abc
from typing import Any, Dict

from ..config import Config


class BaseDataProvider(abc.ABC):
    """Interface for retrieving dashboard data."""

    name: str = "base"

    def __init__(self, config: Config) -> None:
        self.config = config

    @abc.abstractmethod
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Return the payload consumed by the frontend."""

    def describe(self) -> Dict[str, Any]:
        """Return metadata about the provider for diagnostics."""

        return {"name": self.name}

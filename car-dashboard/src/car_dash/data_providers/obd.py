"""OBD-II data provider using the python-OBD library."""

from __future__ import annotations

import logging
import time
from typing import Any, Dict

from .base import BaseDataProvider

try:
    import obd  # type: ignore
except ImportError:  # pragma: no cover - optional dependency
    obd = None

LOGGER = logging.getLogger(__name__)


class OBDDataProvider(BaseDataProvider):
    name = "obd"

    def __init__(self, config):
        super().__init__(config)
        if obd is None:
            raise RuntimeError("python-OBD is not installed")
        self.connection = obd.Async()
        if not self.connection.is_connected():
            LOGGER.warning("OBD-II connection not established; check adapter.")
        self.connection.watch(obd.commands.SPEED)
        self.connection.watch(obd.commands.RPM)
        self.connection.watch(obd.commands.COOLANT_TEMP)
        self.connection.watch(obd.commands.FUEL_LEVEL)
        self.connection.watch(obd.commands.INTAKE_TEMP)
        self.connection.start()

    def get_dashboard_data(self) -> Dict[str, Any]:
        speed = self._value_of(obd.commands.SPEED, default=0)
        rpm = self._value_of(obd.commands.RPM, default=0)
        coolant = self._value_of(obd.commands.COOLANT_TEMP, default=0)
        fuel = self._value_of(obd.commands.FUEL_LEVEL, default=0)
        intake = self._value_of(obd.commands.INTAKE_TEMP, default=0)

        return {
            "timestamp": time.time(),
            "summary": {
                "title": self.config.dashboard_title,
                "speed": speed,
                "odometer": None,
            },
            "drivetrain": {
                "rpm": rpm,
                "battery_voltage": None,
                "coolant_temp": coolant,
            },
            "environment": {
                "cabin_temp": intake,
                "outside_temp": None,
                "humidity": None,
            },
            "trip": {
                "fuel_level": fuel,
                "range_km": None,
                "efficiency": None,
            },
        }

    def describe(self) -> Dict[str, Any]:
        data = super().describe()
        data.update({"port": getattr(self.connection, "port_name", "auto")})
        return data

    def _value_of(self, cmd, default):
        response = self.connection.query(cmd)
        if response and response.value is not None:
            value = response.value.magnitude if hasattr(response.value, "magnitude") else response.value
            try:
                return round(float(value), 2)
            except (TypeError, ValueError):
                return default
        return default

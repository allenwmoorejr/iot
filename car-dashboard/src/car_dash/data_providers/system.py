"""System metrics provider for Pi diagnostics."""

from __future__ import annotations

import time
import psutil
from typing import Any, Dict

from .base import BaseDataProvider


class SystemDataProvider(BaseDataProvider):
    name = "system"

    def get_dashboard_data(self) -> Dict[str, Any]:
        temps = psutil.sensors_temperatures()
        cpu_temp = None
        if "cpu-thermal" in temps:
            cpu_temp = temps["cpu-thermal"][0].current
        elif "coretemp" in temps:
            cpu_temp = temps["coretemp"][0].current

        battery = psutil.sensors_battery()
        power_percent = battery.percent if battery else None

        return {
            "timestamp": time.time(),
            "summary": {
                "title": self.config.dashboard_title,
                "speed": 0,
                "odometer": None,
            },
            "drivetrain": {
                "rpm": 0,
                "battery_voltage": None,
                "coolant_temp": cpu_temp,
            },
            "environment": {
                "cabin_temp": cpu_temp,
                "outside_temp": None,
                "humidity": None,
            },
            "trip": {
                "fuel_level": power_percent,
                "range_km": None,
                "efficiency": None,
            },
        }

"""Mock data provider that generates synthetic yet plausible vehicle data."""

from __future__ import annotations

import random
import time
from typing import Any, Dict

from .base import BaseDataProvider


class MockDataProvider(BaseDataProvider):
    name = "mock"

    def __init__(self, config):
        super().__init__(config)
        random.seed(time.time())
        self._odometer = 42000.0

    def get_dashboard_data(self) -> Dict[str, Any]:
        self._odometer += random.uniform(0.01, 0.05)
        rpm = random.randint(700, 3200)
        speed = max(0, min(120, random.gauss(45, 15)))
        battery = max(11.5, min(14.5, random.gauss(13.2, 0.3)))
        coolant = max(70, min(110, random.gauss(90, 5)))
        cabin_temp = random.gauss(22, 1.5)
        outside_temp = random.gauss(18, 4)

        return {
            "timestamp": time.time(),
            "summary": {
                "title": self.config.dashboard_title,
                "odometer": round(self._odometer, 1),
                "speed": round(speed, 1),
            },
            "drivetrain": {
                "rpm": rpm,
                "battery_voltage": round(battery, 2),
                "coolant_temp": round(coolant, 1),
            },
            "environment": {
                "cabin_temp": round(cabin_temp, 1),
                "outside_temp": round(outside_temp, 1),
                "humidity": random.randint(30, 80),
            },
            "trip": {
                "fuel_level": round(random.uniform(15, 80), 1),
                "range_km": int(random.uniform(150, 480)),
                "efficiency": round(random.uniform(5.5, 8.5), 1),
            },
        }

    def describe(self) -> Dict[str, Any]:
        data = super().describe()
        data.update({"mode": "synthetic"})
        return data

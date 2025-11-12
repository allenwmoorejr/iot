# Raspberry Pi Car Dashboard

This module provides a lightweight touchscreen-friendly dashboard designed to run on a Raspberry Pi-powered infotainment panel. It offers a modern single-page frontend that polls a backend service for real-time vehicle and environmental data.

## Features
- Responsive dashboard layout tailored for 7"–10" Raspberry Pi touchscreens.
- Configurable data providers with a pluggable architecture (`python-OBD`, `Adafruit_DHT`, mock provider).
- Gradient-based modern UI with simple animations and large typography for glanceable information.
- REST API that the frontend polls every few seconds for updated metrics.
- Graceful fallback to generated demo data when physical sensors are not present.

## Hardware overview
- Raspberry Pi 4 (2 GB RAM minimum recommended) or newer.
- Official Raspberry Pi 7" touchscreen display (or compatible HDMI touch display).
- 12V to 5V buck converter rated for at least 3A to integrate with vehicle power.
- Optional: OBD-II Bluetooth/Wired adapter, temperature/humidity sensors.

Ensure the buck converter is fused and wired to an accessory circuit so the dashboard powers down with the vehicle. Consider enabling the Pi's power management (e.g., via a UPS HAT or ignition-sensing relay) for safe shutdowns.

## Software architecture
```
+----------------------+       +--------------------------+
| Touchscreen frontend | <---> | Flask REST data service  |
| (HTML/JS/CSS)        |       | (runs on Raspberry Pi)   |
+----------------------+       +--------------------------+
                                         |
                                         v
                              +--------------------------+
                              | Data providers (OBD-II,  |
                              | sensors, mock generator) |
                              +--------------------------+
```

The `car_dash` package exposes a Flask application. The default provider uses generated demo data so you can test the UI on any machine. On the Pi you can switch to the OBD-II provider or write additional providers for your specific sensors.

## Quick start (development laptop)
```bash
cd car-dashboard
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export CAR_DASH_PROVIDER=mock
export FLASK_APP=car_dash.app:create_app
flask run --host=0.0.0.0 --port=8000
```
Open `http://localhost:8000` in a browser to preview the dashboard.

## Deploying to the Raspberry Pi
1. Flash Raspberry Pi OS Lite and enable SSH and Wi-Fi as needed.
2. Install system dependencies:
   ```bash
   sudo apt update && sudo apt install -y python3-venv python3-pip git
   ```
3. Clone this repository and follow the quick start instructions above on the Pi. Use `CAR_DASH_PROVIDER=obd` once you have an OBD-II interface configured.
4. Add a systemd service to run the dashboard on boot (see `scripts/install-car-dash-service.sh` in this repository for an example service installer).
5. Configure Chromium in kiosk mode or use `kivy`/`qt` if you prefer native rendering. The provided UI is web-based and works well in kiosk mode.

## Configuring data providers
Set the `CAR_DASH_PROVIDER` environment variable to one of:
- `mock` (default) – Generates synthetic but realistic-looking data for demos.
- `obd` – Uses `python-OBD` to query vehicle telemetry.
- `system` – Reports Raspberry Pi metrics (CPU temp, voltage) for diagnostics.

Additional providers can be created by subclassing `BaseDataProvider` inside `car_dash/data_providers/base.py` and registering them in `data_providers/__init__.py`.

## Frontend customization
The frontend lives in `car_dash/templates/index.html`, `static/css/styles.css`, and `static/js/dashboard.js`. Modify the CSS gradients, typography, and card layout to tweak the look and feel. Assets are intentionally lightweight so the dashboard performs well on Pi hardware.

## Screenshots
The UI renders a hero header with vehicle status and three primary cards: drivetrain, environment, and trip metrics. It uses subtle shadows and gradients inspired by automotive UI design.

## Next steps
- Integrate with GPS hardware for live maps and navigation overlays.
- Add voice control or integrate with CarPlay/Android Auto if licensing permits.
- Expand data providers for tire pressure, battery monitoring, and dashcam feeds.


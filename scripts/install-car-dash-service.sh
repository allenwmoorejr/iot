#!/usr/bin/env bash
# Installer for deploying the Raspberry Pi car dashboard as a systemd service.
# Usage: sudo CAR_DASH_PROVIDER=obd ./scripts/install-car-dash-service.sh
set -euo pipefail

SERVICE_NAME="car-dash"
INSTALL_ROOT="/opt/car-dash"
USER="pi"

if [[ $EUID -ne 0 ]]; then
  echo "This installer must be run as root (use sudo)." >&2
  exit 1
fi

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

mkdir -p "$INSTALL_ROOT"
rsync -a --delete "${REPO_ROOT}/car-dashboard/" "$INSTALL_ROOT/"

if [[ ! -d "$INSTALL_ROOT/.venv" ]]; then
  python3 -m venv "$INSTALL_ROOT/.venv"
fi

"$INSTALL_ROOT/.venv/bin/pip" install --upgrade pip
"$INSTALL_ROOT/.venv/bin/pip" install -r "$INSTALL_ROOT/requirements.txt"

cat >/etc/systemd/system/${SERVICE_NAME}.service <<SERVICE
[Unit]
Description=Raspberry Pi Touchscreen Car Dashboard
After=network-online.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${INSTALL_ROOT}
Environment=CAR_DASH_PROVIDER="${CAR_DASH_PROVIDER:-mock}"
Environment=FLASK_APP=car_dash.app:create_app
ExecStart=${INSTALL_ROOT}/.venv/bin/flask run --host=0.0.0.0 --port=8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service
systemctl restart ${SERVICE_NAME}.service

echo "Service installed. Configure your browser kiosk to open http://localhost:8000".

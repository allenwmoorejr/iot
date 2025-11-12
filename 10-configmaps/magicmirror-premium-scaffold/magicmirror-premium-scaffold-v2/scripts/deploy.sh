#!/usr/bin/env bash
set -euo pipefail
CHART_DIR="${1:-./helm-magicmirror}"
NAMESPACE="${2:-suite}"
helm upgrade --install magicmirror "$CHART_DIR" -n "$NAMESPACE" --create-namespace
kubectl -n "$NAMESPACE" get pods -l app=magicmirror-server

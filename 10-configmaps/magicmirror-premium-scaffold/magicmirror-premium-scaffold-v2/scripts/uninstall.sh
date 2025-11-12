#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="${1:-suite}"
helm uninstall magicmirror -n "$NAMESPACE" || true
kubectl -n "$NAMESPACE" delete ingress spotify-callback || true
kubectl -n "$NAMESPACE" delete svc spotify-callback || true
kubectl -n "$NAMESPACE" delete deploy spotify-callback || true

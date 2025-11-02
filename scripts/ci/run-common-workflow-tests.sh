#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/validate-kubernetes-manifests.sh"
"${SCRIPT_DIR}/check-terraform-format.sh"

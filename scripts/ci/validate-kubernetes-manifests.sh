#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$REPO_ROOT"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found on PATH. Install kubectl or run inside a container image that provides it." >&2
  exit 1
fi

mapfile -t manifests < <(find "$REPO_ROOT" -type f \( -name '*.yml' -o -name '*.yaml' \) ! -name '*:Zone.Identifier' ! -path '*/.terraform/*' ! -path '*/.git/*' | sort)

if [ "${#manifests[@]}" -eq 0 ]; then
  echo "No Kubernetes manifests found. Skipping validation."
  exit 0
fi

status=0
for manifest in "${manifests[@]}"; do
  rel_path="${manifest#$REPO_ROOT/}"
  echo "Validating ${rel_path}"
  if ! kubectl apply --dry-run=client --validate=true --filename "$manifest" >/tmp/kubectl-validate.log 2>&1; then
    echo "Validation failed for ${rel_path}" >&2
    cat /tmp/kubectl-validate.log >&2
    status=1
  fi
  rm -f /tmp/kubectl-validate.log
done

if [ "$status" -ne 0 ]; then
  echo "One or more Kubernetes manifests failed validation." >&2
else
  echo "All Kubernetes manifests validated successfully."
fi

exit "$status"

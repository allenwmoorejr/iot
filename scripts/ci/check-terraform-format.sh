#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$REPO_ROOT"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found on PATH. Install Terraform or run inside a container image that provides it." >&2
  exit 1
fi

declare -A module_dirs=()
while IFS= read -r tf_file; do
  dir="$(dirname "$tf_file")"
  module_dirs["$dir"]=1
done < <(find "$REPO_ROOT" -type f -name '*.tf' ! -path '*/.terraform/*')

if [ "${#module_dirs[@]}" -eq 0 ]; then
  echo "No Terraform modules found. Skipping format check."
  exit 0
fi

status=0
for dir in "${!module_dirs[@]}"; do
  rel_path="${dir#$REPO_ROOT/}"
  echo "Checking Terraform formatting in ${rel_path}"
  if ! (cd "$dir" && terraform fmt -check -recursive); then
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "Terraform formatting check failed." >&2
else
  echo "Terraform formatting is correct."
fi

exit "$status"

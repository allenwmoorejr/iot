#!/bin/bash
# Test runner script for all validation tests

set -e

echo "======================================"
echo "Running Camera Uploader Unit Tests"
echo "======================================"
cd 30-apps/micro-cam/uploader
python3 -m pytest tests/ -v --tb=short

echo ""
echo "======================================"
echo "Running Kubernetes Manifest Validation"
echo "======================================"
cd ../../../
python3 -m pytest tests/test_kubernetes_manifests.py -v --tb=short

echo ""
echo "======================================"
echo "Running Terraform Configuration Tests"
echo "======================================"
python3 -m pytest tests/test_terraform_configuration.py -v --tb=short

echo ""
echo "======================================"
echo "All tests completed successfully!"
echo "======================================"
# Test Suite

This directory contains comprehensive tests for the IoT infrastructure repository.

## Test Organization

### 1. Python Unit Tests (`30-apps/micro-cam/uploader/tests/`)
- **test_app.py**: Comprehensive unit tests for the Flask camera uploader application
  - Tests all endpoints (upload, latest.jpg, metrics, healthz)
  - Tests error handling and edge cases
  - Tests file system operations
  - Tests Prometheus metrics integration
  - Tests concurrent access scenarios

### 2. Kubernetes Manifest Validation (`test_kubernetes_manifests.py`)
- Validates YAML syntax and structure
- Tests Traefik middleware configurations
- Tests ingress rules and TLS configuration
- Validates security configurations
- Tests namespace configurations
- Checks YAML best practices

### 3. Terraform Configuration Tests (`test_terraform_configuration.py`)
- Validates Terraform file structure
- Tests variable definitions and types
- Tests provider configurations
- Validates resource definitions
- Tests template files
- Checks for security best practices (no hardcoded credentials)

## Running Tests

### Prerequisites
```bash
pip install -r 30-apps/micro-cam/uploader/requirements-test.txt
```

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Specific Test Suites

#### Python Unit Tests Only
```bash
cd 30-apps/micro-cam/uploader
python3 -m pytest tests/ -v
```

#### Kubernetes Validation Only
```bash
python3 -m pytest tests/test_kubernetes_manifests.py -v
```

#### Terraform Validation Only
```bash
python3 -m pytest tests/test_terraform_configuration.py -v
```

### Run with Coverage
```bash
cd 30-apps/micro-cam/uploader
python3 -m pytest tests/ --cov=app --cov-report=html --cov-report=term
```

## Test Coverage

### Camera Uploader App (app.py)
- ✅ All endpoints tested
- ✅ Happy paths and error conditions
- ✅ File operations and edge cases
- ✅ Metrics and health checks
- ✅ Environment configuration
- ✅ Concurrent access scenarios

### Kubernetes Manifests
- ✅ YAML syntax validation
- ✅ Resource structure validation
- ✅ Security configuration checks
- ✅ Best practices compliance

### Terraform Configuration
- ✅ File structure validation
- ✅ Variable and output validation
- ✅ Provider configuration checks
- ✅ Security best practices
- ✅ Template file validation

## Continuous Integration

These tests are designed to run in CI/CD pipelines. Consider adding them to your GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r 30-apps/micro-cam/uploader/requirements-test.txt
      - name: Run tests
        run: ./tests/run_tests.sh
```

## Contributing

When adding new features:
1. Add corresponding unit tests
2. Ensure all tests pass
3. Maintain or improve code coverage
4. Follow existing test patterns and naming conventions
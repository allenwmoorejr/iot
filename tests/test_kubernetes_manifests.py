"""
Validation tests for Kubernetes YAML manifests.
Tests ensure manifests are valid, well-formed, and follow best practices.
"""
import pytest
import yaml
import os
import re
from pathlib import Path

# Base directory is parent of tests directory
BASE_DIR = Path(__file__).parent.parent

class TestTraefikMiddlewares:
    """Test suite for Traefik middleware configurations."""
    
    @pytest.fixture
    def middleware_file(self):
        """Load the traefik-middlewares.yaml file."""
        path = BASE_DIR / "10-configmaps" / "traefik-middlewares.yaml"
        with open(path, 'r') as f:
            return list(yaml.safe_load_all(f))
    
    def test_middleware_file_is_valid_yaml(self, middleware_file):
        """Test that middleware file is valid YAML."""
        assert middleware_file is not None
        assert len(middleware_file) > 0
    
    def test_all_middlewares_present(self, middleware_file):
        """Test that all expected middlewares are defined."""
        middleware_names = [doc['metadata']['name'] for doc in middleware_file]
        
        expected = ['redirect-https', 'allow-lan', 'security-headers', 'compress']
        for name in expected:
            assert name in middleware_names, f"Middleware {name} not found"
    
    def test_redirect_https_middleware(self, middleware_file):
        """Test redirect-https middleware configuration."""
        redirect_https = next(
            (doc for doc in middleware_file if doc['metadata']['name'] == 'redirect-https'),
            None
        )
        
        assert redirect_https is not None
        assert redirect_https['apiVersion'] == 'traefik.io/v1alpha1'
        assert redirect_https['kind'] == 'Middleware'
        assert redirect_https['metadata']['namespace'] == 'suite'
        assert redirect_https['spec']['redirectScheme']['scheme'] == 'https'
        assert redirect_https['spec']['redirectScheme']['permanent'] is True
    
    def test_allow_lan_middleware(self, middleware_file):
        """Test allow-lan middleware configuration."""
        allow_lan = next(
            (doc for doc in middleware_file if doc['metadata']['name'] == 'allow-lan'),
            None
        )
        
        assert allow_lan is not None
        assert allow_lan['metadata']['namespace'] == 'suite'
        assert 'ipWhiteList' in allow_lan['spec']
        assert 'sourceRange' in allow_lan['spec']['ipWhiteList']
        
        # Verify LAN CIDR is included
        source_ranges = allow_lan['spec']['ipWhiteList']['sourceRange']
        assert '192.168.50.0/24' in source_ranges
    
    def test_security_headers_middleware(self, middleware_file):
        """Test security-headers middleware configuration."""
        security_headers = next(
            (doc for doc in middleware_file if doc['metadata']['name'] == 'security-headers'),
            None
        )
        
        assert security_headers is not None
        headers = security_headers['spec']['headers']
        
        # Verify security headers are properly configured
        assert headers['frameDeny'] is True
        assert headers['contentTypeNosniff'] is True
        assert headers['browserXssFilter'] is True
        assert headers['stsSeconds'] == 31536000  # 1 year
    
    def test_compress_middleware(self, middleware_file):
        """Test compress middleware configuration."""
        compress = next(
            (doc for doc in middleware_file if doc['metadata']['name'] == 'compress'),
            None
        )
        
        assert compress is not None
        assert compress['metadata']['namespace'] == 'suite'
        assert 'compress' in compress['spec']
        assert compress['spec']['compress'] == {} or compress['spec']['compress'] is None
    
    def test_all_middlewares_in_suite_namespace(self, middleware_file):
        """Test that all middlewares are in the suite namespace."""
        for doc in middleware_file:
            assert doc['metadata']['namespace'] == 'suite'
    
    def test_middleware_api_version(self, middleware_file):
        """Test that all middlewares use correct API version."""
        for doc in middleware_file:
            assert doc['apiVersion'] == 'traefik.io/v1alpha1'
            assert doc['kind'] == 'Middleware'


class TestSuiteIngress:
    """Test suite for suite-apps ingress configuration."""
    
    @pytest.fixture
    def ingress_file(self):
        """Load the suite-apps.yaml file."""
        path = BASE_DIR / "40-ingress" / "suite-apps.yaml"
        with open(path, 'r') as f:
            return yaml.safe_load(f)
    
    def test_ingress_file_is_valid_yaml(self, ingress_file):
        """Test that ingress file is valid YAML."""
        assert ingress_file is not None
    
    def test_ingress_basic_structure(self, ingress_file):
        """Test ingress has correct basic structure."""
        assert ingress_file['apiVersion'] == 'networking.k8s.io/v1'
        assert ingress_file['kind'] == 'Ingress'
        assert ingress_file['metadata']['name'] == 'suite-apps'
        assert ingress_file['metadata']['namespace'] == 'suite'
    
    def test_ingress_uses_traefik_class(self, ingress_file):
        """Test that ingress uses traefik class."""
        assert ingress_file['spec']['ingressClassName'] == 'traefik'
    
    def test_ingress_middleware_annotation(self, ingress_file):
        """Test that redirect-https middleware is applied."""
        annotations = ingress_file['metadata']['annotations']
        middleware_value = annotations.get('traefik.ingress.kubernetes.io/router.middlewares')
        
        assert middleware_value == 'suite-redirect-https@kubernetescrd'
    
    def test_ingress_tls_configuration(self, ingress_file):
        """Test TLS configuration."""
        tls = ingress_file['spec']['tls']
        
        assert len(tls) > 0
        assert tls[0]['secretName'] == 'suite-home-arpa-tls'
        
        expected_hosts = ['scrypted.suite.home.arpa', 'homebridge.suite.home.arpa']
        for host in expected_hosts:
            assert host in tls[0]['hosts']
    
    def test_ingress_rules_structure(self, ingress_file):
        """Test ingress rules are properly structured."""
        rules = ingress_file['spec']['rules']
        
        assert len(rules) == 2
        
        # Test each rule has required fields
        for rule in rules:
            assert 'host' in rule
            assert 'http' in rule
            assert 'paths' in rule['http']
    
    def test_scrypted_rule(self, ingress_file):
        """Test scrypted service rule."""
        rules = ingress_file['spec']['rules']
        scrypted_rule = next(
            (r for r in rules if r['host'] == 'scrypted.suite.home.arpa'),
            None
        )
        
        assert scrypted_rule is not None
        path = scrypted_rule['http']['paths'][0]
        
        assert path['path'] == '/'
        assert path['pathType'] == 'Prefix'
        assert path['backend']['service']['name'] == 'scrypted'
        assert path['backend']['service']['port']['number'] == 11080
    
    def test_homebridge_rule(self, ingress_file):
        """Test homebridge service rule."""
        rules = ingress_file['spec']['rules']
        homebridge_rule = next(
            (r for r in rules if r['host'] == 'homebridge.suite.home.arpa'),
            None
        )
        
        assert homebridge_rule is not None
        path = homebridge_rule['http']['paths'][0]
        
        assert path['path'] == '/'
        assert path['pathType'] == 'Prefix'
        assert path['backend']['service']['name'] == 'homebridge'
        assert path['backend']['service']['port']['number'] == 8581
    
    def test_hosts_match_tls_hosts(self, ingress_file):
        """Test that rule hosts match TLS hosts."""
        tls_hosts = set(ingress_file['spec']['tls'][0]['hosts'])
        rule_hosts = {rule['host'] for rule in ingress_file['spec']['rules']}
        
        assert tls_hosts == rule_hosts


class TestNamespaceConfiguration:
    """Test suite for namespace configuration."""
    
    @pytest.fixture
    def namespace_file(self):
        """Load the namespace.yaml file."""
        path = BASE_DIR / "00-namespace" / "namespace.yaml"
        with open(path, 'r') as f:
            return yaml.safe_load(f)
    
    def test_namespace_is_valid(self, namespace_file):
        """Test namespace YAML is valid."""
        assert namespace_file is not None
        assert namespace_file['apiVersion'] == 'v1'
        assert namespace_file['kind'] == 'Namespace'
    
    def test_namespace_name(self, namespace_file):
        """Test namespace has correct name."""
        assert namespace_file['metadata']['name'] == 'suite'


class TestYAMLBestPractices:
    """Test YAML files follow best practices."""
    
    def get_yaml_files(self):
        """Get all YAML files in the repository."""
        yaml_files = []
        for pattern in ['*.yaml', '*.yml']:
            yaml_files.extend(BASE_DIR.glob(f'**/{pattern}'))
        
        # Filter out Zone.Identifier files
        yaml_files = [f for f in yaml_files if 'Zone.Identifier' not in str(f)]
        return yaml_files
    
    def test_yaml_files_parse_correctly(self):
        """Test that all YAML files can be parsed."""
        yaml_files = self.get_yaml_files()
        
        for yaml_file in yaml_files:
            try:
                with open(yaml_file, 'r') as f:
                    # Try parsing as single document
                    try:
                        yaml.safe_load(f)
                    except yaml.YAMLError:
                        # Try parsing as multi-document
                        f.seek(0)
                        list(yaml.safe_load_all(f))
            except (OSError, yaml.YAMLError) as e:
                pytest.fail(f"Failed to parse {yaml_file}: {e}")
    
    def test_no_tabs_in_yaml(self):
        """Test that YAML files don't contain tabs."""
        yaml_files = self.get_yaml_files()
        
        for yaml_file in yaml_files:
            with open(yaml_file, 'r') as f:
                content = f.read()
                assert '\t' not in content, f"File {yaml_file} contains tabs"
    
    def test_proper_indentation(self):
        """Test YAML files use consistent indentation (2 spaces)."""
        yaml_files = self.get_yaml_files()
        
        for yaml_file in yaml_files:
            with open(yaml_file, 'r') as f:
                lines = f.readlines()
                
            for i, line in enumerate(lines, 1):
                if line.strip() and line[0] == ' ':
                    # Count leading spaces
                    spaces = len(line) - len(line.lstrip())
                    # Should be multiple of 2
                    assert spaces % 2 == 0, \
                        f"{yaml_file}:{i} has odd indentation ({spaces} spaces)"


class TestIngressSecurityConfiguration:
    """Test security aspects of ingress configurations."""
    
    def test_https_redirect_is_configured(self):
        """Test that HTTPS redirect middleware is configured and applied."""
        # Load middleware file
        middleware_path = BASE_DIR / "10-configmaps" / "traefik-middlewares.yaml"
        with open(middleware_path, 'r') as f:
            middlewares = list(yaml.safe_load_all(f))
        
        # Verify redirect middleware exists
        redirect_mw = next(
            (m for m in middlewares if m['metadata']['name'] == 'redirect-https'),
            None
        )
        assert redirect_mw is not None
        
        # Load ingress file
        ingress_path = BASE_DIR / "40-ingress" / "suite-apps.yaml"
        with open(ingress_path, 'r') as f:
            ingress = yaml.safe_load(f)
        
        # Verify ingress uses the middleware
        annotations = ingress['metadata']['annotations']
        assert 'suite-redirect-https@kubernetescrd' in annotations.get(
            'traefik.ingress.kubernetes.io/router.middlewares', ''
        )
    
    def test_tls_secret_is_configured(self):
        """Test that TLS secret is properly configured."""
        ingress_path = BASE_DIR / "40-ingress" / "suite-apps.yaml"
        with open(ingress_path, 'r') as f:
            ingress = yaml.safe_load(f)
        
        tls = ingress['spec']['tls']
        assert len(tls) > 0
        assert 'secretName' in tls[0]
        assert tls[0]['secretName'] == 'suite-home-arpa-tls'
    
    def test_security_headers_middleware_exists(self):
        """Test that security headers middleware is defined."""
        middleware_path = BASE_DIR / "10-configmaps" / "traefik-middlewares.yaml"
        with open(middleware_path, 'r') as f:
            middlewares = list(yaml.safe_load_all(f))
        
        security_mw = next(
            (m for m in middlewares if m['metadata']['name'] == 'security-headers'),
            None
        )
        
        assert security_mw is not None
        headers = security_mw['spec']['headers']
        
        # Verify critical security headers
        assert headers.get('frameDeny') is True
        assert headers.get('contentTypeNosniff') is True
        assert headers.get('browserXssFilter') is True
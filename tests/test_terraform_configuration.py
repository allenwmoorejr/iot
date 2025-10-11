"""
Validation tests for Terraform infrastructure configuration.
Tests ensure Terraform files are valid and follow best practices.
"""
import pytest
import subprocess
import os
import re
from pathlib import Path


BASE_DIR = Path(__file__).parent.parent
TERRAFORM_DIR = BASE_DIR / "60-terraform" / "k3s-workers"


class TestTerraformConfiguration:
    """Test Terraform configuration validity."""
    
    @pytest.fixture(scope="class")
    def terraform_dir(self):
        """Ensure terraform directory exists."""
        assert TERRAFORM_DIR.exists(), f"Terraform directory {TERRAFORM_DIR} not found"
        return TERRAFORM_DIR
    
    def test_terraform_files_exist(self, terraform_dir):
        """Test that required Terraform files exist."""
        required_files = [
            'providers.tf',
            'variables.tf',
            'cloud.tf',
            'onprem.tf',
            'outputs.tf'
        ]
        
        for file in required_files:
            file_path = terraform_dir / file
            assert file_path.exists(), f"Required file {file} not found"
    
    def test_terraform_file_extensions(self, terraform_dir):
        """Test that Terraform files have .tf extension."""
        tf_files = list(terraform_dir.glob('*.tf'))
        assert len(tf_files) > 0, "No .tf files found"
        
        # Check no .tf.json files (not using JSON format)
        tf_json_files = list(terraform_dir.glob('*.tf.json'))
        assert len(tf_json_files) == 0, "Found .tf.json files, should use HCL format"
    
    def test_gitignore_exists(self, terraform_dir):
        """Test that .gitignore exists to exclude terraform state."""
        gitignore = terraform_dir / '.gitignore'
        assert gitignore.exists(), ".gitignore not found in terraform directory"


class TestTerraformVariables:
    """Test Terraform variables configuration."""
    
    @pytest.fixture
    def variables_content(self):
        """Read variables.tf file."""
        path = TERRAFORM_DIR / "variables.tf"
        with open(path, 'r') as f:
            return f.read()
    
    def test_required_variables_defined(self, variables_content):
        """Test that required variables are defined."""
        required_vars = [
            'k3s_url',
            'k3s_token',
            'aws_region',
            'aws_instance_type',
            'aws_key_name'
        ]
        
        for var in required_vars:
            assert f'variable "{var}"' in variables_content, \
                f"Required variable {var} not found"
    
    def test_sensitive_variables_marked(self, variables_content):
        """Test that sensitive variables are marked as sensitive."""
        # k3s_token should be marked sensitive
        token_var_match = re.search(
            r'variable "k3s_token".*?{(.*?)}',
            variables_content,
            re.DOTALL
        )
        
        assert token_var_match is not None
        token_block = token_var_match.group(1)
        assert 'sensitive = true' in token_block or 'sensitive=true' in token_block
    
    def test_variables_have_descriptions(self, variables_content):
        """Test that variables have descriptions."""
        # Find all variable blocks
        variables = re.findall(
            r'variable "([^"]+)".*?{(.*?)}',
            variables_content,
            re.DOTALL
        )
        
        for var_name, var_block in variables:
            assert 'description' in var_block, \
                f"Variable {var_name} missing description"
    
    def test_variables_have_types(self, variables_content):
        """Test that variables have type definitions."""
        variables = re.findall(
            r'variable "([^"]+)".*?{(.*?)}',
            variables_content,
            re.DOTALL
        )
        
        for var_name, var_block in variables:
            assert 'type' in var_block, \
                f"Variable {var_name} missing type definition"
    
    def test_default_values_appropriate(self, variables_content):
        """Test that default values are appropriate."""
        # aws_instance_type should default to free tier
        assert 't2.micro' in variables_content or 't3.micro' in variables_content
        
        # aws_region should have a default
        region_match = re.search(
            r'variable "aws_region".*?default\s*=\s*"([^"]+)"',
            variables_content,
            re.DOTALL
        )
        assert region_match is not None


class TestTerraformProviders:
    """Test Terraform providers configuration."""
    
    @pytest.fixture
    def providers_content(self):
        """Read providers.tf file."""
        path = TERRAFORM_DIR / "providers.tf"
        with open(path, 'r') as f:
            return f.read()
    
    def test_required_providers_declared(self, providers_content):
        """Test that required providers are declared."""
        assert 'required_providers' in providers_content
        
        # Should have AWS provider
        assert 'aws' in providers_content
    
    def test_terraform_version_constraint(self, providers_content):
        """Test that Terraform version is constrained."""
        assert 'terraform' in providers_content
        # Should have required_version
        assert 'required_version' in providers_content or '>=' in providers_content


class TestTerraformOutputs:
    """Test Terraform outputs configuration."""
    
    @pytest.fixture
    def outputs_content(self):
        """Read outputs.tf file."""
        path = TERRAFORM_DIR / "outputs.tf"
        with open(path, 'r') as f:
            return f.read()
    
    def test_outputs_exist(self, outputs_content):
        """Test that output variables are defined."""
        # Should have at least one output
        assert 'output' in outputs_content
    
    def test_outputs_have_descriptions(self, outputs_content):
        """Test that outputs have descriptions."""
        outputs = re.findall(
            r'output "([^"]+)".*?{(.*?)}',
            outputs_content,
            re.DOTALL
        )
        
        assert len(outputs) > 0, "No outputs found"
        
        for output_name, output_block in outputs:
            assert 'description' in output_block, \
                f"Output {output_name} missing description"


class TestTerraformResources:
    """Test Terraform resource definitions."""
    
    @pytest.fixture
    def cloud_content(self):
        """Read cloud.tf file."""
        path = TERRAFORM_DIR / "cloud.tf"
        with open(path, 'r') as f:
            return f.read()
    
    @pytest.fixture
    def onprem_content(self):
        """Read onprem.tf file."""
        path = TERRAFORM_DIR / "onprem.tf"
        with open(path, 'r') as f:
            return f.read()
    
    def test_aws_resources_defined(self, cloud_content):
        """Test that AWS resources are defined."""
        # Should have security group
        assert 'aws_security_group' in cloud_content or 'resource "aws_security_group"' in cloud_content
        
        # Should have EC2 instance
        assert 'aws_instance' in cloud_content or 'resource "aws_instance"' in cloud_content
    
    def test_security_group_rules(self, cloud_content):
        """Test that security group has appropriate rules."""
        # Should have ingress rules
        assert 'ingress' in cloud_content
        
        # Should have egress rules
        assert 'egress' in cloud_content
    
    def test_k3s_agent_configuration(self, cloud_content, onprem_content):
        """Test that k3s agent is properly configured."""
        # Should reference k3s_url and k3s_token variables
        combined_content = cloud_content + onprem_content
        assert 'var.k3s_url' in combined_content
        assert 'var.k3s_token' in combined_content


class TestTerraformTemplates:
    """Test Terraform template files."""
    
    def test_template_files_exist(self):
        """Test that template files exist."""
        templates_dir = TERRAFORM_DIR / "templates"
        assert templates_dir.exists(), "Templates directory not found"
        
        # Check for expected templates
        expected_templates = [
            'cloud-init.yaml.tftpl',
            'k3s-agent.sh.tftpl'
        ]
        
        for template in expected_templates:
            template_path = templates_dir / template
            assert template_path.exists(), f"Template {template} not found"
    
    def test_cloud_init_template_structure(self):
        """Test cloud-init template is valid."""
        template_path = TERRAFORM_DIR / "templates" / "cloud-init.yaml.tftpl"
        with open(template_path, 'r') as f:
            content = f.read()
        
        # Should have cloud-config header
        assert '#cloud-config' in content or 'cloud-config' in content
    
    def test_k3s_agent_script_template(self):
        """Test k3s agent script template."""
        template_path = TERRAFORM_DIR / "templates" / "k3s-agent.sh.tftpl"
        with open(template_path, 'r') as f:
            content = f.read()
        
        # Should reference k3s installation
        assert 'k3s' in content.lower()


class TestTerraformBestPractices:
    """Test Terraform files follow best practices."""
    
    def test_no_hardcoded_credentials(self):
        """Test that no credentials are hardcoded."""
        tf_files = list(TERRAFORM_DIR.glob('*.tf'))
        
        patterns = [
            r'password\s*=\s*"[^"]+"',
            r'secret\s*=\s*"[^"]+"',
            r'token\s*=\s*"[^"]+"',
            r'access_key\s*=\s*"[^"]+"',
            r'secret_key\s*=\s*"[^"]+"'
        ]
        
        for tf_file in tf_files:
            with open(tf_file, 'r') as f:
                content = f.read()
            
            for pattern in patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                # Filter out variable references
                actual_hardcoded = [
                    m for m in matches 
                    if 'var.' not in m and 'data.' not in m
                ]
                assert len(actual_hardcoded) == 0, \
                    f"Found hardcoded credentials in {tf_file}: {actual_hardcoded}"
    
    def test_resources_have_names_or_tags(self):
        """Test that resources have identifiable names or tags."""
        resource_files = ['cloud.tf', 'onprem.tf']
        
        for file in resource_files:
            path = TERRAFORM_DIR / file
            with open(path, 'r') as f:
                content = f.read()
            
            # Find resource blocks
            resources = re.findall(
                r'resource "([^"]+)" "([^"]+)"',
                content
            )
            
            for resource_type, resource_name in resources:
                # Resource should be identifiable
                assert resource_name, f"Resource {resource_type} has empty name"
    
    def test_consistent_indentation(self):
        """Test that Terraform files use consistent indentation."""
        tf_files = list(TERRAFORM_DIR.glob('*.tf'))
        
        for tf_file in tf_files:
            with open(tf_file, 'r') as f:
                lines = f.readlines()
            
            for i, line in enumerate(lines, 1):
                if line.strip() and line[0] == ' ':
                    spaces = len(line) - len(line.lstrip())
                    # Should be multiple of 2
                    assert spaces % 2 == 0, \
                        f"{tf_file}:{i} has odd indentation ({spaces} spaces)"
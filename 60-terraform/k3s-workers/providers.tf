terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.42"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# -------- AWS (shared: Route53, future EC2/EKS) --------
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# -------- Kubernetes / Helm (use your local kubeconfig) --------
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# -------- Cloudflare (only used if you choose it) --------
provider "cloudflare" {
  # If you use Cloudflare, set CLOUDFLARE_API_TOKEN env var or var.cloudflare_api_token
  api_token = try(var.cloudflare_api_token, null)
}

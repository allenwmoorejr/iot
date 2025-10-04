terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "libvirt" {
  uri = var.libvirt_uri
}

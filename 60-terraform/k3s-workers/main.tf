locals {
  use_cloudflare = lower(var.external_dns_provider) == "cloudflare"
  use_route53    = lower(var.external_dns_provider) == "route53"
}

# ---------- Namespaces ----------
resource "kubernetes_namespace" "networking" {
  metadata { name = "networking" }
}

resource "kubernetes_namespace" "monitoring" {
  count = var.monitoring_enable ? 1 : 0
  metadata { name = "monitoring" }
}

# ---------- MetalLB ----------
resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.8" # stable at time of writing

  # Install CRDs first-time
  set {
    name  = "crds.enabled"
    value = true
  }

  # Address pools
  values = [yamlencode({
    ipAddressPools = [{
      name      = "default-pool"
      addresses = var.metallb_address_pool
    }]
    l2Advertisements = [{ ipAddressPools = ["default-pool"] }]
  })]
}

# ---------- Ingress (Traefik) ----------
resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "29.0.0"

  values = [yamlencode({
    deployment = { kind = "Deployment" }
    ingressClass = {
      enabled        = true
      isDefaultClass = true
      name           = var.ingress_class
    }
    service = {
      spec = {
        type            = "LoadBalancer"
        loadBalancerIPs = [] # let MetalLB allocate from pool
      }
    }
    logs = { general = { level = "INFO" } }
  })]
}

# ---------- External-DNS (Cloudflare) ----------
# Secret holding the Cloudflare API token (only if using Cloudflare)
resource "kubernetes_secret" "external_dns_cf" {
  count = local.use_cloudflare ? 1 : 0
  metadata {
    name      = "external-dns-credentials"
    namespace = kubernetes_namespace.networking.metadata[0].name
  }
  data = {
    api-token = base64encode(var.cloudflare_api_token) # required
  }
  type = "Opaque"
}

resource "helm_release" "external_dns_cloudflare" {
  count      = local.use_cloudflare ? 1 : 0
  name       = "external-dns"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [yamlencode({
    provider      = "cloudflare"
    domainFilters = [var.domain_name]
    interval      = "1m"
    policy        = "sync"
    txtOwnerId    = var.cluster_name
    sources       = ["ingress", "service"]
    extraEnvVars = [{
      name = "CF_API_TOKEN"
      valueFrom = {
        secretKeyRef = {
          name = "external-dns-credentials"
          key  = "api-token"
        }
      }
    }]
  })]
}

# ---------- External-DNS (Route53) ----------
# If using Route53, the pod needs AWS creds; simplest path is an access key/secret in a Secret.
# (You can swap to IRSA if you later run on EKS.)
resource "kubernetes_secret" "external_dns_aws" {
  count = local.use_route53 ? 1 : 0
  metadata {
    name      = "external-dns-aws"
    namespace = kubernetes_namespace.networking.metadata[0].name
  }
  data = {
    # Store base64-encoded strings; variables should hold plain text.
    aws_access_key_id     = base64encode(var.aws_access_key_id)
    aws_secret_access_key = base64encode(var.aws_secret_access_key)
  }
  type = "Opaque"
}

resource "helm_release" "external_dns_route53" {
  count      = local.use_route53 ? 1 : 0
  name       = "external-dns"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"

  values = [yamlencode({
    provider      = "aws"
    registry      = "txt"
    txtOwnerId    = var.cluster_name
    domainFilters = [var.domain_name]
    sources       = ["ingress", "service"]
    interval      = "1m"
    env = [
      {
        name  = "AWS_REGION"
        value = var.aws_region
      }
    ]
    extraEnvVars = [
      {
        name = "AWS_ACCESS_KEY_ID"
        valueFrom = {
          secretKeyRef = { name = "external-dns-aws", key = "aws_access_key_id" }
        }
      },
      {
        name = "AWS_SECRET_ACCESS_KEY"
        valueFrom = {
          secretKeyRef = { name = "external-dns-aws", key = "aws_secret_access_key" }
        }
      }
    ]
  })]
}

# ---------- (Optional) Monitoring: kube-prometheus-stack ----------
resource "helm_release" "kps" {
  count      = var.monitoring_enable ? 1 : 0
  name       = "monitoring"
  namespace  = one(kubernetes_namespace.monitoring[*].metadata[0].name)
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "66.3.1"

  # Keep defaults sane; we’ll expose Grafana via Traefik.
  values = [yamlencode({
    grafana = {
      adminUser     = var.grafana_admin_user
      adminPassword = var.grafana_admin_password
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class
        hosts            = ["grafana.${var.domain_name}"]
      }
    }
    prometheus = {
      ingress = {
        enabled = false
      }
    }
    alertmanager = {
      ingress = {
        enabled = false
      }
    }
  })]
}


# ---------- Namespaces ----------
resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
  }
}

resource "kubernetes_namespace" "monitoring" {
  count = var.monitoring_enable ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

# ---------- MetalLB (skip CRDs; they already exist) ----------
resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.8"
  skip_crds  = true

  values = [yamlencode({
    ipAddressPools = [{
      name      = "default-pool"
      addresses = var.metallb_address_pool
    }]
    l2Advertisements = [{
      ipAddressPools = ["default-pool"]
    }]
  })]
}

# ---------- Traefik (adopt existing release in ns "traefik") ----------
resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = false
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "37.1.1" # match your cluster

  values = [yamlencode({
    deployment = { kind = "Deployment" }
    ingressClass = {
      enabled        = true
      isDefaultClass = true
      name           = var.ingress_class
    }
    service = {
      spec = {
        type = "LoadBalancer"
      }
    }
  })]
}

# ---------- External-DNS (Cloudflare) ----------
resource "kubernetes_secret" "external_dns_cf" {
  count = lower(var.external_dns_provider) == "cloudflare" ? 1 : 0
  metadata {
    name      = "external-dns-credentials"
    namespace = kubernetes_namespace.networking.metadata[0].name
  }
  data = {
    api-token = base64encode(var.cloudflare_api_token)
  }
  type = "Opaque"
}

resource "helm_release" "external_dns_cloudflare" {
  count      = lower(var.external_dns_provider) == "cloudflare" ? 1 : 0
  name       = "external-dns"
  namespace  = kubernetes_namespace.networking.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.0"
  wait       = true
  timeout    = 600

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

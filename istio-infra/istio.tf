# =========================================================================
# Helm release, used to manage helm charts
# =========================================================================
resource "helm_release" "istio-base" {
  name             = var.istio_base_name
  namespace        = var.istio_system_namespace
  create_namespace = var.ensure_namespace_creation
  version          = var.chart_version
  repository       = var.helm_repo_url
  chart            = var.istio_base_chart
  #force_update     = var.force_update
  #recreate_pods    = var.recreate_pods
}
# =========================================================================
# Deploy istiod component of Istio using helm chart
# https://istio.io/latest/blog/2020/istiod/
# =========================================================================
resource "helm_release" "istiod" {
  name              = var.istiod_name
  namespace         = var.istio_system_namespace
  dependency_update = true
  repository        = var.helm_repo_url
  chart             = var.istiod_name
  version           = var.chart_version
  atomic            = true
  lint              = true

  # postrender block runs a custom script (kustomize.sh) after Helm has rendered the Kubernetes manifests but before they are applied to the cluster.
  postrender {
    binary_path = "${path.module}/istiod-kustomize/kustomize.sh"
    args        = ["${path.module}"]
  }

  values = [
    yamlencode({
      meshConfig = {
        accessLogFile = var.log_file
      }
    })
  ]
  depends_on = [helm_release.istio-base]
}
# =========================================================================
# Deploy gateway component of istio, ingress gateway
# $ helm install istio-ingress istio/gateway -n istio-ingress --wait
# =========================================================================
resource "helm_release" "istio-ingress" {
  name              = var.istio_ingress
  namespace         = var.istio_ingress
  create_namespace  = var.ensure_namespace_creation
  dependency_update = true
  repository        = var.helm_repo_url
  chart             = var.istio_gw_chart
  version           = var.chart_version
  atomic            = true
  postrender {
    binary_path = "${path.module}/gateway-kustomize/kustomize.sh"
    args        = ["${path.module}"]
  }
  values = [
    yamlencode(
      {
        labels = {
          app   = ""
          istio = var.istio_ingress_gw
        }
      }
    )
  ]
  lint       = true
  depends_on = [helm_release.istio-base, helm_release.istiod]
}
# =========================================================================
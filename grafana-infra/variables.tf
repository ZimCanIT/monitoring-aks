# =========================================================================
# Grafana dashboard api token and URL, set as environment variables from az-infra outptus.tf
# =========================================================================
variable "token" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "Grafana dashboard auth. token, set as env. variable from outputs.tf in aks-infra sub-dir"
}
variable "url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "Grafana dashboard enpoint URL, set as env. variable from outputs.tf in aks-infra sub-dir"
}
locals {
  istio_dashboards = {
    istio_control_plane_dashboard  = file("dashboards/7645.json"),
    istio_mesh_dashboard           = file("dashboards/7639.json"),
    istio_service_dashboard        = file("dashboards/7636.json"),
    istio_workload_dashboard       = file("dashboards/7630.json"),
    istio_wasm_extension_dashboard = file("dashboards/13277.json")
  }
}
# =========================================================================
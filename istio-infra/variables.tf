# =========================================================================
# Helm chart istio conf.
# =========================================================================
variable "helm_repo_url" {
  description = "HELM repository url where chart is located"
  type        = string
  default     = "https://istio-release.storage.googleapis.com/charts"
}
variable "chart_version" {
  type    = string
  default = "1.17.1"
}
variable "istio_base_chart" {
  type    = string
  default = "base"
}
variable "istio_base_name" {
  type    = string
  default = "istio-base"
}
variable "istio_system_namespace" {
  type    = string
  default = "istio-system"
}
variable "istiod_name" {
  type    = string
  default = "istiod"
}
variable "log_file" {
  type    = string
  default = "/dev/stdout"
}
variable "istio_ingress_gw" {
  type    = string
  default = "ingressgateway"
}
variable "istio_gw_chart" {
  description = "Name of gateway HELM chart to deploy from the istio HELM repo"
  type        = string
  default     = "gateway"
}
variable "istio_ingress" {
  type    = string
  default = "istio-ingress"
}
variable "ensure_namespace_creation" {
  description = "Ensures namespace, istio-ingress, ss created. If non-existent."
  type        = string
  default     = "true"
}
# =========================================================================
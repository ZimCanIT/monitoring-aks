# =========================================================================
# Kubernetes cluster config 
# =========================================================================
output "kube_config" {
  description = "Raw Kubernetes config to be used by [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) and other compatible tools."
  value       = module.aks.kube_config_raw
  sensitive   = true
}
output "grafana_name" {
  description = "Azure managed grafana dashboard name, set as env. variable (windows)."
  value       = "export GRAFANA_NAME=$(az grafana list -g ${azurerm_resource_group.rg.name} -o json | jq -r '.[0].name')"
}
output "grafana_url" {
  description = "Grafana endpoint URL as an environment variable (windows)"
  value       = "export TF_VAR_url='${azurerm_dashboard_grafana.aks_dash.endpoint}'"
}
output "grafana_token" {
  description = "Grafana dashboard temp 5 minute authentication token, set as env. variable (windows)"
  value       = "export TF_VAR_token=$(az grafana api-key create --key $(date +%s) --name aks-zcit-grafana-dash -g aks-rg -r editor --time-to-live 5m -o json | jq -r .key)"
}
# =========================================================================
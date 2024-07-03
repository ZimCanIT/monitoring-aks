# =========================================================================
# Istio grafana dashboards
# =========================================================================
resource "grafana_dashboard" "istio_dashboards" {
  for_each    = local.istio_dashboards
  config_json = each.value
  overwrite   = true
}
# =========================================================================
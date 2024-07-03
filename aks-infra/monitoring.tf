# =========================================================================
# Azure monitor prometheus workspace, data collection endpoint, rules and aks cluster association to Azure monitor workspace
# https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-grafana
# https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview#endpoints
# =========================================================================
resource "azurerm_monitor_workspace" "prometheus" {
  name                          = "${local.prefix}prometheus-istio-wkspace"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  tags                          = local.common_tags
}
resource "azurerm_monitor_data_collection_endpoint" "endpoint" {
  name                          = "${local.prefix}prometheus-${azurerm_resource_group.rg.location}-istio"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  public_network_access_enabled = true
  kind                          = var.collection_kind
  tags                          = local.common_tags
}
resource "azurerm_monitor_data_collection_rule" "prometheus_metrics_rule" {
  name                        = "${local.prefix}prometheus-${azurerm_resource_group.rg.location}-istio-rule"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.endpoint.id
  kind                        = var.collection_kind
  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = "${local.prefix}monitoring-acc1"
    }
  }
  data_flow {
    streams      = var.prometheus_streams
    destinations = ["${local.prefix}monitoring-acc1"]
  }
  data_sources {
    prometheus_forwarder {
      streams = var.prometheus_streams
      name    = "${local.prefix}prometheus-data-source"
    }
  }
  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on  = [azurerm_monitor_data_collection_endpoint.endpoint]
}
resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
  name = "${local.prefix}prometheus-${azurerm_resource_group.rg.location}-istio"
  # should be virtual machine scale set for aks nodes
  target_resource_id      = module.aks.aks_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus_metrics_rule.id
  description             = "Association of data collection rule with AKS."
  depends_on = [
    module.aks, # dependency set on aks cluster being made first. Otherwise, DCR won't link to cluster
    azurerm_monitor_data_collection_rule.prometheus_metrics_rule
  ]
}
# =========================================================================
# Grafana dashboard and role assignments 
# =========================================================================
resource "azurerm_dashboard_grafana" "aks_dash" {
  name                              = "${local.prefix}zcit-grafana-dash"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true
  grafana_major_version             = 9
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }
  identity {
    type = var.grafana_identity
  }
  tags = local.common_tags
}
resource "azurerm_role_assignment" "monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.grafana_reader_role
  principal_id         = azurerm_dashboard_grafana.aks_dash.identity[0].principal_id
}
resource "azurerm_role_assignment" "monitoring_data_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = var.grafana_data_reader_role
  principal_id         = azurerm_dashboard_grafana.aks_dash.identity[0].principal_id
}
resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.aks_dash.id
  role_definition_name = var.grafna_admin_role
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Give current client admin access to Managed Grafana instance."
}
# =========================================================================
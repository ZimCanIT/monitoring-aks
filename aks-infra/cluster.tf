# =========================================================================
# SSH key gen for aks auth.
# =========================================================================
resource "azapi_resource_action" "ssh_public_key_gen" {
  type                   = var.ssh_gen_type
  resource_id            = azapi_resource.ssh_public_key.id
  action                 = var.ssh_action
  method                 = var.ssh_method
  response_export_values = var.ssh_exported_vals
}
resource "azapi_resource" "ssh_public_key" {
  type      = var.ssh_gen_type
  name      = "${local.prefix}zcit-ssh"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}
# =========================================================================
#  AKS cluster, uses latest version of kubenetes in deployed region (WestEurope)
# =========================================================================
module "aks" {
  source                            = "Azure/aks/azurerm"
  version                           = "9.0.0"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  cluster_name                      = "${local.prefix}zcit-cluster"
  admin_username                    = var.aks_admin_username
  public_ssh_key                    = azapi_resource_action.ssh_public_key_gen.output.publicKey
  role_based_access_control_enabled = true
  rbac_aad                          = false
  prefix                            = var.aks_resource_prefix
  network_plugin                    = var.aks_network_plugin
  vnet_subnet_id                    = module.network.vnet_subnets[0]
  os_disk_size_gb                   = 50
  sku_tier                          = var.aks_sku
  private_cluster_enabled           = false
  enable_auto_scaling               = true
  enable_host_encryption            = false
  log_analytics_workspace_enabled   = false
  agents_min_count                  = 1
  agents_max_count                  = 5
  # `null` set while `enable_auto_scaling` == `true`. Aavoids possible `agents_count` changes.
  agents_max_pods           = 100
  agents_count              = null
  agents_pool_name          = var.aks_pool_name
  agents_availability_zones = var.aks_az
  agents_type               = var.aks_vm_type
  agents_size               = var.aks_vm_size
  monitor_metrics           = {}

  agents_labels = local.aks_node_labels
  agents_tags   = local.aks_node_pool_tags

  network_policy             = var.aks_network_policy
  net_profile_dns_service_ip = var.aks_dns_svcip
  net_profile_service_cidr   = var.aks_service_cidr

  key_vault_secrets_provider_enabled = true
  secret_rotation_enabled            = true
  secret_rotation_interval           = var.aks_secret_rotation

  node_pools = local.node_pools

  storage_profile_enabled             = true
  storage_profile_blob_driver_enabled = true

  network_contributor_role_assigned_subnet_ids = { "system" = module.network.vnet_subnets[0] }

  web_app_routing = { dns_zone_id = "" }

  depends_on = [module.network]
}
# =========================================================================
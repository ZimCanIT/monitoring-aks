module "network" {
  source              = "github.com/ZimCanIT/terraform-azurerm-network"
  vnet_name           = azurerm_resource_group.rg.name
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = "10.52.0.0/16"
  subnet_prefixes     = ["10.52.0.0/20"]
  subnet_names        = ["system"]
  depends_on          = [azurerm_resource_group.rg]
  use_for_each        = true
  subnet_private_endpoint_network_policies = {
    "system" = "Disabled"
  }
}
# =========================================================================
# SSH key gen
# =========================================================================
variable "ssh_gen_type" {
  type    = string
  default = "Microsoft.Compute/sshPublicKeys@2022-11-01"
}
variable "ssh_action" {
  type    = string
  default = "generateKeyPair"
}
variable "ssh_method" {
  type    = string
  default = "POST"
}
variable "ssh_exported_vals" {
  type    = list(string)
  default = ["publicKey", "privateKey"]
}
# =========================================================================
# Resource group location and cluster config 
# =========================================================================
variable "rg_location" {
  description = "Resource group deployment location"
  type        = string
  default     = "westeurope"
}
variable "node_count" {
  type        = number
  description = "No. of nodes for node pool"
  default     = 3
}
variable "msi_id" {
  description = "The Managed Service Identity ID"
  type        = string
  default     = null
}
variable "aks_admin_username" {
  description = "Cluster admin username"
  type        = string
  default     = "aksazureadmin"
}
variable "aks_pool_name" {
  type    = string
  default = "system"
}
variable "aks_resource_prefix" {
  description = "Prefix for the resources created in the specified Azure Resource Group"
  type        = string
  default     = "istio"
}
variable "aks_vm_size" {
  description = "The default virtual machine size for the Kubernetes agents."
  type        = string
  default     = "Standard_D2_v2"
}
variable "aks_vm_type" {
  type    = string
  default = "VirtualMachineScaleSets"
}
variable "aks_az" {
  description = "Availability Zones in which this Kubernetes Cluster should be located."
  type        = list(string)
  #default     = ["1", "2"] - use only when deploying in personal directory and not Hybrid MSP as below
  default = ["1"]
}
variable "aks_sku" {
  description = "SKU Tier that should be used for this Kubernetes Cluster"
  type        = string
  default     = "Standard"
}
variable "aks_secret_rotation" {
  type    = string
  default = "3m"
}
variable "aks_network_plugin" {
  type    = string
  default = "azure"
}
variable "aks_network_policy" {
  type    = string
  default = "azure"
}
variable "aks_dns_svcip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)."
  type        = string
  default     = "10.0.0.10"
}
variable "aks_service_cidr" {
  description = "The Network Range used by the Kubernetes service."
  type        = string
  default     = "10.0.0.0/16"
}
# =========================================================================
# Monitoring
# =========================================================================
variable "collection_kind" {
  type    = string
  default = "Linux"
}
variable "prometheus_streams" {
  type    = list(string)
  default = ["Microsoft-PrometheusMetrics"]
}
variable "grafana_identity" {
  type    = string
  default = "SystemAssigned"
}
variable "grafana_reader_role" {
  type    = string
  default = "Monitoring Reader"
}
variable "grafana_data_reader_role" {
  type    = string
  default = "Monitoring Data Reader"
}
variable "grafna_admin_role" {
  type    = string
  default = "Grafana Admin"
}
# =========================================================================
# Locals
# =========================================================================
locals {
  prefix = "aks-"
  # map of Kubernetes labels which should be applied to nodes in the Default Node Pool.
  aks_node_labels = {
    "nodepool" : "defaultnodepool"
  }
  # map of tags to assign to node pool 
  aks_node_pool_tags = {
    "Agent" : "defaultnodepoolagent"
  }
  common_tags = {
    lab         = "moitoring-aks-w-prometheus-and-grafana"
    environment = "dev"
    owner       = "jmhpe"
  }
  node_pools = {
    user = {
      name                = "user"
      vm_size             = var.aks_vm_size
      enable_auto_scaling = true
      node_count          = 1
      min_count           = 1
      max_count           = 5
      vnet_subnet_id      = module.network.vnet_subnets[0]
    },
    ingress = {
      name                = "ingress"
      vm_size             = var.aks_vm_size
      enable_auto_scaling = true
      node_count          = 1
      min_count           = 1
      max_count           = 2
      vnet_subnet_id      = module.network.vnet_subnets[0]
    },
  }
}
# =========================================================================

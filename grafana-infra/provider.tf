# =========================================================================
# Terraform config block, resource provides and remote backend
# =========================================================================
terraform {
  required_version = ">=1.1.0" # min version of Terraform required to run configuration
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.10"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.2.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfmstate-rg"
    storage_account_name = "zcitakstfmacc2" # remove no.2 when deploying in personal env
    container_name       = "tfstate"
    key                  = "grafana.tfmstate"
  }
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "grafana" {
  url  = var.url
  auth = var.token
}
# =========================================================================

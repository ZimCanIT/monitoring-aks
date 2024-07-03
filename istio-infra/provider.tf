# =========================================================================
# Terraform config block, resource provides and remote backend
# =========================================================================
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfmstate-rg"
    storage_account_name = "zcitakstfmacc2" # remove no.2 when deploying in personal env
    container_name       = "tfstate"
    key                  = "istio.tfmstate"
  }
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "kubectl" {
  config_path = "~/.kube/config"

}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"

  }
}
provider "random" {}
# =========================================================================

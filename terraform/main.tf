# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "aks" {
  source = "./modules/aks"

  cluster_name        = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  location           = var.location
  node_count         = var.node_count
  node_size          = var.node_size
  kubernetes_version = var.kubernetes_version
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true  # Keep admin enabled for backup access
}

# Role assignment for AKS to ACR
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = module.aks.kubelet_identity
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
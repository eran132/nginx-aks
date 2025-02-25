# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix         = var.cluster_name
  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable RBAC
  role_based_access_control_enabled = true
}

# Note: ACR pull role assignment commented out due to permission restrictions
# If you have Owner or User Access Administrator role, uncomment this block

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}


# outputs.tf
output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.rg.name
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config
  sensitive   = true
}

output "cluster_identity" {
  description = "System-assigned managed identity of the cluster"
  value       = module.aks.cluster_identity
}

output "cluster_fqdn" {
  description = "FQDN of the Azure Kubernetes Managed Cluster"
  value       = module.aks.cluster_fqdn
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The username for the container registry admin account"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "The password for the container registry admin account"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}
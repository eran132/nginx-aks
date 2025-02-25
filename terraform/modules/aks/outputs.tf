# outputs.tf
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "cluster_identity" {
  value = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
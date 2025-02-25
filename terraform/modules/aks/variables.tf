# variables.tf
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "Size of the nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null  # Will use the latest available version
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
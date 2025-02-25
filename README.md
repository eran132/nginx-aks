# AKS Terraform ArgoCD Demo

This project demonstrates how to deploy a monitored Nginx application on Azure Kubernetes Service (AKS) using Terraform, ArgoCD, Prometheus, and Alertmanager.

## Project Structure

```
project-root/
├── terraform/               # Terraform configuration
│   ├── modules/
│   │   └── aks/            # AKS module
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Root variables
│   ├── outputs.tf          # Root outputs
│   └── terraform.tfvars    # Variable values
│
├── kubernetes/             # Kubernetes manifests
│   ├── argocd/             # ArgoCD configuration
│   │   ├── install/
│   │   └── applications/
│   ├── nginx/              # Nginx application
│   └── monitoring/         # Prometheus and Alertmanager
│
├── scripts/                # Helper scripts
│   ├── setup.ps1           # Setup script
│   └── cleanup.ps1         # Cleanup script
│
└── README.md               # This file
```

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://www.terraform.io/downloads.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) or equivalent Docker engine
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (optional)

## Getting Started

### 1. Set Environment Variables

Before running any scripts, set up the required environment variables:

```powershell
# Azure authentication variables
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"
$env:ARM_TENANT_ID = "your-tenant-id"
$env:ARM_CLIENT_ID = "your-client-id"         # Optional for service principal
$env:ARM_CLIENT_SECRET = "your-client-secret" # Optional for service principal

# Project variables
$env:TF_VAR_location = "eastus"               # Or your preferred region
$env:TF_VAR_cluster_name = "aks-demo-cluster"
$env:TF_VAR_resource_group_name = "aks-demo-rg"
```

You can get your subscription ID by running:
```powershell
az account show --query id -o tsv
```

### 2. Set Up Infrastructure

```powershell
# Login to Azure (if not using service principal)
az login

# Deploy infrastructure
cd scripts
.\setup.ps1
```

### 3. Install and Configure ArgoCD

Follow the steps in the [Installation Steps](./installation-steps.md) document.

Alternatively, you can use our script which automates the ArgoCD installation:

```powershell
# Make sure you're connected to your AKS cluster first
cd scripts
.\install-argocd.ps1
```

### 4. Testing ACR Integration

```powershell
# Make sure Docker Desktop or equivalent is running
cd scripts
.\test-acr-pull.ps1
```

This script will verify that your AKS cluster can pull images from your private ACR using the system-managed identity. It requires Docker to be running on your local machine to build and push the test image.

- ArgoCD UI: Access via the LoadBalancer IP
- Nginx: Access via the LoadBalancer IP
- Prometheus: Use port forwarding or access via the LoadBalancer IP
- Alertmanager: Use port forwarding or access via the LoadBalancer IP

### 5. Clean Up

When you're done, clean up the resources to avoid incurring costs:

```powershell
cd scripts
.\cleanup.ps1
```

## Monitoring

### Prometheus

- Access the Prometheus UI to view metrics
- Explore predefined queries for Nginx metrics
- View active alerts

### Alertmanager

- Access the Alertmanager UI to view and manage alerts
- Configure notifications (console by default, Slack is optional)

## ArgoCD

### Accessing ArgoCD

- ArgoCD UI: `http://<EXTERNAL-IP>`
- Default username: `admin`
- Get the initial password: 
  ```powershell
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
  ```

### Managing Applications with ArgoCD

- View the status of applications in the ArgoCD UI
- Sync applications manually if needed
- View the deployment history and rollback if necessary

## Assumptions and Constraints

- The AKS cluster uses the default network configuration
- Persistent volumes are used for Prometheus data storage
- HTTPS is not configured for this demo
- This setup is intended for demonstration purposes only, not production use
- Scripts assume PowerShell environment on Windows
- For cost control, all resources should be destroyed when not in use
- NetworkWatcher resources might need manual cleanup after Terraform destroy

## Time Spent

Approximately 2 hours for the complete setup and documentation.

## License

MIT
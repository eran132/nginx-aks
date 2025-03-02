# AKS Terraform ArgoCD Demo

This project demonstrates how to deploy a monitored Nginx application on Azure Kubernetes Service (AKS) using Terraform, ArgoCD, Prometheus, and Alertmanager.

## Project Structure

```
project-root/
├── terraform/               # Terraform configuration
│   ├── modules/
│   │   └── aks/            # AKS module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Root variables
│   ├── outputs.tf          # Root outputs
│   └── terraform.tfvars    # Variable values
│
├── kubernetes/             # Kubernetes manifests
│   ├── argocd/             # ArgoCD configuration
│   │   ├── install/
│   │   │   └── install.yaml    # ArgoCD installation manifest
│   │   └── applications/
│   │       ├── nginx-app.yaml       # ArgoCD app for Nginx
│   │       ├── prometheus-app.yaml  # ArgoCD app for Prometheus (Helm)
│   │       └── alertmanager-app.yaml # ArgoCD app for Alertmanager (Helm)
│   │
│   └── nginx/              # Nginx application manifests
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
│
├── scripts/                # Helper scripts
│   ├── setup.ps1                # Setup infrastructure
│   ├── cleanup.ps1              # Clean up resources
│   ├── argocd-install.ps1       # Install ArgoCD
│   ├── test-acr-pull.ps1        # Test ACR integration
│   ├── nginx-load-test.ps1      # Generate load on Nginx for testing alerts
│   ├── prom2alertmanager.ps1    # Fix Prometheus-Alertmanager integration
│   └── acr-test-deployment.yaml # Test deployment for ACR
│
├── .gitignore              # Git ignore file
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

```powershell
# Make sure you're connected to your AKS cluster first
cd scripts
.\argocd-install.ps1
```

This script automates the ArgoCD installation and provides the initial admin password.

### 4. Testing ACR Integration

```powershell
# Make sure Docker Desktop or equivalent is running
cd scripts
.\test-acr-pull.ps1
```

This script verifies that your AKS cluster can pull images from your private ACR using the system-managed identity. It requires Docker to be running on your local machine to build and push the test image.

### 5. Deploy Applications with ArgoCD

Applications are deployed automatically by ArgoCD using GitOps principles. The following applications are configured:

- Nginx application: `kubernetes/argocd/applications/nginx-app.yaml`
- Prometheus monitoring: `kubernetes/argocd/applications/prometheus-app.yaml`
- Alertmanager: `kubernetes/argocd/applications/alertmanager-app.yaml`

Simply applying these files to your cluster will start the GitOps deployment process:

```powershell
kubectl apply -f kubernetes/argocd/applications/nginx-app.yaml
kubectl apply -f kubernetes/argocd/applications/prometheus-app.yaml
kubectl apply -f kubernetes/argocd/applications/alertmanager-app.yaml
```

### 6. Accessing Applications

- ArgoCD UI: Access via the LoadBalancer IP
- Nginx: Access via the LoadBalancer IP
- Prometheus: Use port forwarding (`kubectl port-forward svc/prometheus-server -n monitoring 9090:80`)
- Alertmanager: Use port forwarding (`kubectl port-forward svc/prometheus-alertmanager -n monitoring 9093:9093`)

### 7. Testing Alerts

A script is provided to generate load on the Nginx pods to trigger the CPU usage alerts:

```powershell
.\scripts\nginx-load-test.ps1
```

### 8. Clean Up

When you're done, clean up the resources to avoid incurring costs:

```powershell
cd scripts
.\cleanup.ps1
```

## Monitoring

### Prometheus

Prometheus is deployed using the official Helm chart via ArgoCD. It's configured to:
- Monitor the Nginx application
- Track CPU and other resource usage
- Set up alert rules for high CPU usage
- Send alerts to Alertmanager

### Alertmanager

Alertmanager is also deployed using an official Helm chart via ArgoCD. It:
- Receives alerts from Prometheus
- Handles alert grouping and deduplication
- Routes notifications to the console (with optional Slack integration)

## ArgoCD

### Accessing ArgoCD

- ArgoCD UI: Access via the LoadBalancer IP
- Default username: `admin`
- Get the initial password (provided during installation): 
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
# scripts/setup.ps1
Write-Host "Creating AKS Infrastructure..." -ForegroundColor Green

try {
    # First clean any existing entries for this cluster to avoid prompts
    Write-Host "Cleaning existing kubeconfig entries first..." -ForegroundColor Yellow
    kubectl config delete-context aks-demo-cluster 2>$null
    kubectl config delete-cluster aks-demo-cluster 2>$null
    kubectl config delete-user clusterUser_aks-demo-rg_aks-demo-cluster 2>$null
    
    # Get all contexts, clusters, and users from kubeconfig
    $contexts = kubectl config get-contexts -o name 2>$null
    $clusters = kubectl config get-clusters 2>$null
    $users = kubectl config get-users 2>$null
    
    # Delete anything that matches our cluster pattern
    foreach ($context in $contexts) {
        if ($context -like "*aks-demo*") {
            Write-Host "Deleting context: $context" -ForegroundColor Yellow
            kubectl config delete-context $context 2>$null
        }
    }
    
    foreach ($cluster in $clusters) {
        if ($cluster -like "*aks-demo*") {
            Write-Host "Deleting cluster: $cluster" -ForegroundColor Yellow
            kubectl config delete-cluster $cluster 2>$null
        }
    }
    
    foreach ($user in $users) {
        if ($user -like "*aks-demo*") {
            Write-Host "Deleting user: $user" -ForegroundColor Yellow
            kubectl config delete-user $user 2>$null
        }
    }

    Set-Location -Path ..\terraform
    
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init

    Write-Host "Planning Terraform deployment..." -ForegroundColor Yellow
    terraform plan

    Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
    terraform apply -auto-approve

    Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
    $rg = (terraform output -raw resource_group_name)
    $cluster = (terraform output -raw cluster_name)
    
    # Try to find Azure CLI in common locations
    $azureCLIPaths = @(
        "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd",
        "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd",
        "$env:ProgramFiles\Azure CLI\az.cmd",
        "$env:LocalAppData\Programs\Microsoft SDKs\Azure\CLI2\az.cmd"
    )
    
    $azPath = $null
    foreach ($path in $azureCLIPaths) {
        if (Test-Path $path) {
            $azPath = $path
            break
        }
    }
    
    if ($azPath) {
        Write-Host "Found Azure CLI at: $azPath" -ForegroundColor Green
        & $azPath aks get-credentials --resource-group $rg --name $cluster --overwrite-existing
        
        # Configure ACR pull permissions using Azure CLI
        $acrName = terraform output -raw acr_login_server
        $acrName = $acrName.Split('.')[0]  # Extract just the name part
        $identity = & $azPath aks show -g $rg -n $cluster --query identityProfile.kubeletidentity.objectId -o tsv
        
        Write-Host "Setting up ACR Pull permissions via Azure CLI..." -ForegroundColor Yellow
        Write-Host "ACR Name: $acrName" -ForegroundColor Yellow
        Write-Host "AKS Kubelet Identity: $identity" -ForegroundColor Yellow
        
        $acrId = & $azPath acr show -n $acrName -g $rg --query id -o tsv
        & $azPath role assignment create --assignee $identity --role "AcrPull" --scope $acrId
        
        Write-Host "ACR Pull permissions configured successfully!" -ForegroundColor Green
    } else {
        Write-Host "Azure CLI not found. Please make sure the Azure CLI is installed and then run:" -ForegroundColor Yellow
        Write-Host "az aks get-credentials --resource-group $rg --name $cluster" -ForegroundColor Yellow
        Write-Host "Then manually configure ACR Pull permissions with:" -ForegroundColor Yellow
        Write-Host "az role assignment create --assignee <identity> --role 'AcrPull' --scope <acr-id>" -ForegroundColor Yellow
    }

    Write-Host "Setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during setup: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..\scripts
}
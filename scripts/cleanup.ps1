# scripts/cleanup.ps1
Write-Host "Starting cleanup process..." -ForegroundColor Yellow

try {
    # Store the current cluster name before destroying it
    $clusterName = $null
    $resourceGroup = $null
    
    try {
        $clusterName = kubectl config current-context
        Write-Host "Current cluster context: $clusterName" -ForegroundColor Yellow
        
        # Try to get the resource group from Terraform output
        Set-Location -Path ..\terraform
        $resourceGroup = terraform output -raw resource_group_name 2>$null
        if (-not $resourceGroup) {
            # If terraform output fails, try to extract from the context name
            if ($clusterName -match "clusterUser_(.+)_(.+)") {
                $resourceGroup = $matches[1]
            }
        }
    } catch {
        Write-Host "Could not determine current cluster context. Continuing with cleanup..." -ForegroundColor Yellow
    }
    
    Write-Host "Destroying AKS Infrastructure..." -ForegroundColor Yellow
    terraform destroy -auto-approve

    # More aggressive cleanup of kubeconfig
    Write-Host "Performing complete kubeconfig cleanup..." -ForegroundColor Yellow
    
    # Try standard context/cluster/user names
    kubectl config delete-context aks-demo-cluster 2>$null
    kubectl config delete-cluster aks-demo-cluster 2>$null
    kubectl config delete-user clusterUser_aks-demo-rg_aks-demo-cluster 2>$null
    
    # Try with resource group if we have it
    if ($resourceGroup) {
        kubectl config delete-context clusterUser_${resourceGroup}_aks-demo-cluster 2>$null
        kubectl config delete-user clusterUser_${resourceGroup}_aks-demo-cluster 2>$null
    }
    
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

    Write-Host "Cleanup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during cleanup: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..\scripts
}
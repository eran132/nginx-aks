# scripts/cleanup.ps1
Write-Host "Starting cleanup process..." -ForegroundColor Yellow

try {
    # Store the current cluster name before destroying it
    $clusterName = $null
    try {
        $clusterName = kubectl config current-context
        Write-Host "Current cluster context: $clusterName" -ForegroundColor Yellow
    } catch {
        Write-Host "Could not determine current cluster context. Continuing with cleanup..." -ForegroundColor Yellow
    }
    
    Set-Location -Path ..\terraform
    
    Write-Host "Destroying AKS Infrastructure..." -ForegroundColor Yellow
    terraform destroy -auto-approve

    # Remove the kubectl context if we have a cluster name
    if ($clusterName) {
        Write-Host "Removing kubectl context for $clusterName..." -ForegroundColor Yellow
        kubectl config delete-context $clusterName
    }

    Write-Host "Cleanup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during cleanup: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..\scripts
}
Write-Host "Creating AKS Infrastructure..." -ForegroundColor Green

try {
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
        & $azPath aks get-credentials --resource-group $rg --name $cluster
    } else {
        Write-Host "Azure CLI not found. Please make sure the Azure CLI is installed and then run:" -ForegroundColor Yellow
        Write-Host "az aks get-credentials --resource-group $rg --name $cluster" -ForegroundColor Yellow
    }

    Write-Host "Setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during setup: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..\scripts
}
# scripts/install-argocd.ps1
Write-Host "Installing ArgoCD on AKS cluster..." -ForegroundColor Green

try {
    # Check if namespace exists
    $namespaceCheck = kubectl get namespace argocd 2>$null
    if (-not $?) {
        Write-Host "Creating ArgoCD namespace..." -ForegroundColor Yellow
        kubectl create namespace argocd
    } else {
        Write-Host "ArgoCD namespace already exists" -ForegroundColor Yellow
    }

    # Install ArgoCD
    Write-Host "Applying ArgoCD manifests..." -ForegroundColor Yellow
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Apply our custom LoadBalancer service
    Write-Host "Applying custom ArgoCD LoadBalancer service..." -ForegroundColor Yellow
    kubectl apply -f ..\kubernetes\argocd\install\install.yaml
    
    # Wait for the pods to be ready
    Write-Host "Waiting for ArgoCD pods to be ready..." -ForegroundColor Yellow
    kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
    
    # Get the LoadBalancer IP
    Write-Host "Getting ArgoCD server LoadBalancer IP..." -ForegroundColor Yellow
    kubectl get svc argocd-server-lb -n argocd
    
    # Get the initial admin password
    Write-Host "Getting initial admin password..." -ForegroundColor Yellow
    $secretCheck = kubectl get secret argocd-initial-admin-secret -n argocd 2>$null
    if ($?) {
        $encodedPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
        $password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
        Write-Host "ArgoCD Initial Admin Password: $password" -ForegroundColor Green
        Write-Host "IMPORTANT: Save this password for logging into ArgoCD!" -ForegroundColor Red
    } else {
        Write-Host "Could not retrieve ArgoCD password. It might have been reset already." -ForegroundColor Yellow
    }
    
    Write-Host "ArgoCD installation completed successfully!" -ForegroundColor Green
    Write-Host "Access the ArgoCD UI using the LoadBalancer IP from above." -ForegroundColor Green
    Write-Host "Username: admin" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during ArgoCD installation: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..
}
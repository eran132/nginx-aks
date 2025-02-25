# scripts/test-acr-pull.ps1
Write-Host "Testing AKS to ACR integration using managed identity..." -ForegroundColor Green

try {
    # Get ACR details from Terraform output
    Set-Location -Path ..\terraform
    $acrLoginServer = terraform output -raw acr_login_server
    $acrUsername = terraform output -raw acr_admin_username
    $acrPassword = terraform output -raw acr_admin_password

    Write-Host "ACR Login Server: $acrLoginServer" -ForegroundColor Yellow
    
    # Create a test deployment that pulls from ACR
    Set-Location -Path ..\scripts
    $deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: acr-test
  labels:
    app: acr-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: acr-test
  template:
    metadata:
      labels:
        app: acr-test
    spec:
      containers:
      - name: nginx
        image: $acrLoginServer/nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: acr-test
spec:
  selector:
    app: acr-test
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
"@

    # Login to ACR using admin credentials to push the test image
    Write-Host "Logging into ACR with admin credentials (for image push only)..." -ForegroundColor Yellow
    docker login $acrLoginServer -u $acrUsername -p $acrPassword

    # Pull and push a test image to ACR
    Write-Host "Pulling and pushing test image to ACR..." -ForegroundColor Yellow
    docker pull nginx:latest
    docker tag nginx:latest "$acrLoginServer/nginx:latest"
    docker push "$acrLoginServer/nginx:latest"

    # Apply the test deployment
    Write-Host "Creating test deployment..." -ForegroundColor Yellow
    $deploymentYaml | Out-File -FilePath "acr-test-deployment.yaml"
    kubectl apply -f "acr-test-deployment.yaml"

    # Wait for the deployment to be ready
    Write-Host "Waiting for deployment to be ready..." -ForegroundColor Yellow
    kubectl rollout status deployment/acr-test --timeout=2m

    # Check if the pod is running
    $podStatus = kubectl get pods -l app=acr-test -o jsonpath='{.items[0].status.phase}'
    
    if ($podStatus -eq "Running") {
        Write-Host "Success! AKS can pull images from ACR using managed identity." -ForegroundColor Green
        Write-Host "This confirms that the role assignment for AcrPull is working correctly." -ForegroundColor Green
    } else {
        Write-Host "Error: Pod is not running. Status: $podStatus" -ForegroundColor Red
        kubectl describe pods -l app=acr-test
    }
}
catch {
    Write-Host "Error occurred during ACR test: $_" -ForegroundColor Red
}
finally {
    Set-Location -Path ..\scripts
}
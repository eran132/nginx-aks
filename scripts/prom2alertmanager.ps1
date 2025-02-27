# Get the Prometheus pod name
$promPod = kubectl get pods -n monitoring -l app=prometheus,component=server -o name | Select-Object -First 1
$promPod = $promPod -replace "pod/", ""

Write-Host "Using Prometheus pod: $promPod"

# Create an extremely simple JSON in the pod (no escaping issues)
kubectl exec -n monitoring $promPod -c prometheus-server -- sh -c 'cat > /tmp/simple-alert.json << EOF
[{"labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test"}}]
EOF'

# Verify the file exists and content is correct
kubectl exec -n monitoring $promPod -c prometheus-server -- cat /tmp/simple-alert.json

# Use wget with post-data directly (no piping)
Write-Host "Sending alert to Alertmanager..."
kubectl exec -n monitoring $promPod -c prometheus-server -- sh -c 'wget -O - --header="Content-Type: application/json" --post-data="$(cat /tmp/simple-alert.json)" http://alertmanager.monitoring.svc.cluster.local:9093/api/v1/alerts'

# Check if the alert was sent
Write-Host "Checking Alertmanager for alert..."
kubectl port-forward svc/alertmanager -n monitoring 9093:9093 &
Write-Host "View alerts at http://localhost:9093" -ForegroundColor Cyan
# Get the Nginx service IP
$nginxIP = kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Found Nginx LoadBalancer IP: $nginxIP" -ForegroundColor Green

# Create a load test function
function Start-LoadTest {
    param(
        [string]$TargetIP,
        [int]$DurationMinutes = 6,
        [int]$ConcurrentRequests = 20
    )

    Write-Host "Starting load test against $TargetIP for $DurationMinutes minutes..." -ForegroundColor Yellow
    $startTime = Get-Date
    $endTime = $startTime.AddMinutes($DurationMinutes)

    while ((Get-Date) -lt $endTime) {
        # Show a progress indicator
        Write-Host "." -NoNewline
        
        # Create multiple concurrent requests
        1..$ConcurrentRequests | ForEach-Object -Parallel {
            try {
                Invoke-WebRequest -Uri "http://$using:TargetIP/" -Method GET -UseBasicParsing -TimeoutSec 1 | Out-Null
            } catch {
                # Ignore errors
            }
        } -ThrottleLimit 20
        
        # Brief pause to prevent overwhelming the system running the script
        Start-Sleep -Milliseconds 100
    }

    Write-Host "`nLoad test completed at $(Get-Date)" -ForegroundColor Green
}

# Run the load test
Start-LoadTest -TargetIP $nginxIP -DurationMinutes 6 -ConcurrentRequests 2000
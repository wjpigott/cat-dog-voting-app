# Traffic Manager Deployment Monitor
# Monitors for when your Traffic Manager becomes available

param(
    [string]$TrafficManagerUrl = "http://voting-app-tm-1636.trafficmanager.net",
    [int]$CheckInterval = 30
)

Write-Host "🔍 TRAFFIC MANAGER DEPLOYMENT MONITOR" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "🌐 Monitoring: $TrafficManagerUrl" -ForegroundColor Cyan
Write-Host "⏱️ Check interval: $CheckInterval seconds" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$checkCount = 0
$startTime = Get-Date

while ($true) {
    $checkCount++
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    Write-Host "🔍 Check #$checkCount - $(Get-Date -Format 'HH:mm:ss') (Elapsed: $($elapsed.ToString('mm\:ss')))" -ForegroundColor Blue
    
    try {
        # Test Traffic Manager URL
        $response = Invoke-WebRequest -Uri $TrafficManagerUrl -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        
        Write-Host "✅ TRAFFIC MANAGER IS LIVE!" -ForegroundColor Green
        Write-Host "🌐 URL: $TrafficManagerUrl" -ForegroundColor Magenta
        Write-Host "📊 Status: $($response.StatusCode)" -ForegroundColor Yellow
        Write-Host "🎯 Routing is active!" -ForegroundColor Green
        
        # Test which backend it's routing to
        try {
            $fullResponse = Invoke-WebRequest -Uri $TrafficManagerUrl -TimeoutSec 10 -ErrorAction Stop
            if ($fullResponse.Content -like "*Azure*") {
                Write-Host "➡️ Currently routing to: Azure AKS (Primary)" -ForegroundColor Green
            }
            elseif ($fullResponse.Content -like "*OnPrem*" -or $fullResponse.Content -like "*on-premises*") {
                Write-Host "➡️ Currently routing to: OnPrem K3s (Backup)" -ForegroundColor Yellow
            }
            else {
                Write-Host "➡️ Currently routing to: Unknown backend" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "➡️ Traffic Manager is responding, routing active" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "🧪 Ready to test failover! Run:" -ForegroundColor Cyan
        Write-Host ".\scripts\test-failover-tm.sh `"$TrafficManagerUrl`"" -ForegroundColor White
        
        break
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*name does not exist*" -or $errorMsg -like "*DNS*") {
            Write-Host "⏳ DNS not propagated yet... (this is normal)" -ForegroundColor Yellow
        }
        elseif ($errorMsg -like "*timeout*") {
            Write-Host "⏳ Connection timeout... (endpoints may be starting)" -ForegroundColor Yellow
        }
        else {
            Write-Host "⏳ Not ready yet: $($errorMsg.Split([Environment]::NewLine)[0])" -ForegroundColor Yellow
        }
    }
    
    # Show individual endpoint status
    Write-Host "📍 Checking individual endpoints..." -ForegroundColor Gray
    
    # Check Azure
    try {
        $azureCheck = Invoke-WebRequest -Uri "http://52.154.54.110" -Method HEAD -TimeoutSec 5 -ErrorAction Stop
        Write-Host "   ✅ Azure AKS: Online (Status: $($azureCheck.StatusCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Azure AKS: Offline" -ForegroundColor Red
    }
    
    # Check OnPrem
    try {
        $onpremCheck = Invoke-WebRequest -Uri "http://66.242.207.21:31514" -Method HEAD -TimeoutSec 5 -ErrorAction Stop
        Write-Host "   ✅ OnPrem K3s: Online (Status: $($onpremCheck.StatusCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ OnPrem K3s: Offline" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Next check in $CheckInterval seconds..." -ForegroundColor DarkGray
    Start-Sleep $CheckInterval
}
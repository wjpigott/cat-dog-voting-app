# Multi-Endpoint Health Monitor
# Monitors both Azure and OnPrem endpoints while setting up Traffic Manager

param(
    [int]$CheckInterval = 10,
    [string]$AzureEndpoint = "http://52.154.54.110",
    [string]$OnPremEndpoint = "http://66.242.207.21:31514"
)

function Test-Endpoint {
    param([string]$Url, [string]$Name)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method HEAD -TimeoutSec 5 -ErrorAction Stop
        return @{
            Name = $Name
            Status = "✅ UP"
            StatusCode = $response.StatusCode
            ResponseTime = "OK"
            Color = "Green"
        }
    }
    catch {
        return @{
            Name = $Name  
            Status = "❌ DOWN"
            StatusCode = "Error"
            ResponseTime = $_.Exception.Message.Split([Environment]::NewLine)[0]
            Color = "Red" 
        }
    }
}

Write-Host "🌐 ENDPOINT HEALTH MONITOR" -ForegroundColor Magenta
Write-Host "Monitoring endpoints for Traffic Manager setup..." -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$counter = 0
while ($true) {
    $counter++
    Clear-Host
    
    Write-Host "🌐 ENDPOINT HEALTH MONITOR - Check #$counter" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "🕐 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Test both endpoints
    $azureStatus = Test-Endpoint -Url $AzureEndpoint -Name "Azure AKS"
    $onpremStatus = Test-Endpoint -Url $OnPremEndpoint -Name "OnPrem K3s"
    
    # Display status
    Write-Host "🔷 $($azureStatus.Name): $($azureStatus.Status)" -ForegroundColor $azureStatus.Color
    Write-Host "   Endpoint: $AzureEndpoint" -ForegroundColor Gray
    Write-Host "   Response: $($azureStatus.ResponseTime)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🏠 $($onpremStatus.Name): $($onpremStatus.Status)" -ForegroundColor $onpremStatus.Color
    Write-Host "   Endpoint: $OnPremEndpoint" -ForegroundColor Gray
    Write-Host "   Response: $($onpremStatus.ResponseTime)" -ForegroundColor Gray
    Write-Host ""
    
    # Show Traffic Manager recommendation
    Write-Host "🎯 TRAFFIC MANAGER ROUTING:" -ForegroundColor Yellow
    if ($azureStatus.Status -like "*UP*" -and $onpremStatus.Status -like "*UP*") {
        Write-Host "   ➡️  Would route to: Azure (Priority 1)" -ForegroundColor Green
        Write-Host "   🔄 Backup available: OnPrem (Priority 2)" -ForegroundColor Cyan
        Write-Host "   ✅ PERFECT TIME to set up Traffic Manager!" -ForegroundColor Green
    }
    elseif ($onpremStatus.Status -like "*UP*") {
        Write-Host "   ➡️  Would route to: OnPrem (Priority 2)" -ForegroundColor Yellow  
        Write-Host "   ⏳ Azure starting up..." -ForegroundColor Orange
    }
    elseif ($azureStatus.Status -like "*UP*") {
        Write-Host "   ➡️  Would route to: Azure (Priority 1)" -ForegroundColor Green
        Write-Host "   ❌ OnPrem unavailable" -ForegroundColor Red
    }
    else {
        Write-Host "   ❌ Both endpoints down" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Next check in $CheckInterval seconds..." -ForegroundColor DarkGray
    Start-Sleep $CheckInterval
}
# External High Availability Load Balancer for Windows
# Runs independently of both Azure and OnPrem clusters
# Provides true failover capability

param(
    [string]$AzureEndpoint = "http://52.154.54.110",
    [string]$OnPremEndpoint = "http://66.242.207.21:31514", 
    [int]$Port = 8080,
    [int]$CheckInterval = 10
)

Write-Host "🚀 Starting External HA Load Balancer on port $Port" -ForegroundColor Green
Write-Host "🎯 Primary: $AzureEndpoint" -ForegroundColor Yellow
Write-Host "🔄 Backup: $OnPremEndpoint" -ForegroundColor Cyan

# Function to check if endpoint is healthy
function Test-EndpointHealth {
    param([string]$Endpoint)
    try {
        $response = Invoke-WebRequest -Uri "$Endpoint/" -Method HEAD -TimeoutSec 5 -ErrorAction Stop
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# Function to get current status
function Get-LoadBalancerStatus {
    $azureStatus = if (Test-EndpointHealth $AzureEndpoint) { "✅ UP" } else { "❌ DOWN" }
    $onpremStatus = if (Test-EndpointHealth $OnPremEndpoint) { "✅ UP" } else { "❌ DOWN" }
    
    return @{
        Azure = $azureStatus
        OnPrem = $onpremStatus
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Main monitoring loop
Write-Host "`n🌐 Load Balancer Status Monitor" -ForegroundColor Magenta
Write-Host "📊 Checking endpoints every $CheckInterval seconds..." -ForegroundColor Gray

while ($true) {
    $status = Get-LoadBalancerStatus
    
    Clear-Host
    Write-Host "🌐 EXTERNAL LOAD BALANCER - HA MODE" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    Write-Host "🎯 Azure AKS:      $($status.Azure)" -ForegroundColor $(if ($status.Azure -like "*UP*") { "Green" } else { "Red" })
    Write-Host "🔄 OnPrem K3s:     $($status.OnPrem)" -ForegroundColor $(if ($status.OnPrem -like "*UP*") { "Green" } else { "Red" })
    Write-Host "🕐 Last Check:     $($status.Timestamp)" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    # Show current routing decision
    if ($status.Azure -like "*UP*") {
        Write-Host "➡️  ROUTING: Primary (Azure AKS)" -ForegroundColor Green
        Write-Host "🌐 Access: $AzureEndpoint" -ForegroundColor Yellow
    }
    elseif ($status.OnPrem -like "*UP*") {
        Write-Host "➡️  ROUTING: Backup (OnPrem K3s)" -ForegroundColor Yellow
        Write-Host "🌐 Access: $OnPremEndpoint" -ForegroundColor Cyan
    }
    else {
        Write-Host "⚠️  ROUTING: ALL BACKENDS DOWN!" -ForegroundColor Red
    }
    
    Write-Host "`nPress Ctrl+C to stop monitoring..." -ForegroundColor Gray
    Start-Sleep $CheckInterval
}
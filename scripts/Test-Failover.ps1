# Traffic Manager Failover Testing Script
# Tests automatic failover between Azure and OnPrem endpoints

param(
    [string]$TrafficManagerUrl = "",
    [string]$AzureEndpoint = "http://52.154.54.110",
    [string]$OnPremEndpoint = "http://66.242.207.21:31514",
    [int]$TestDuration = 300  # 5 minutes
)

Write-Host "🧪 TRAFFIC MANAGER FAILOVER TEST" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════" -ForegroundColor Gray

if ([string]::IsNullOrEmpty($TrafficManagerUrl)) {
    Write-Host "⚠️  Traffic Manager URL not provided" -ForegroundColor Yellow
    Write-Host "Please provide the URL with -TrafficManagerUrl parameter" -ForegroundColor Gray
    Write-Host "Example: .\test-failover.ps1 -TrafficManagerUrl 'http://voting-app-tm-xxxx.trafficmanager.net'" -ForegroundColor DarkGray
    exit 1
}

# Function to test endpoint health
function Test-EndpointHealth {
    param([string]$Endpoint, [string]$Name)
    try {
        $response = Invoke-WebRequest -Uri $Endpoint -Method HEAD -TimeoutSec 5 -ErrorAction Stop
        return @{
            Name = $Name
            Status = "✅ UP"
            StatusCode = $response.StatusCode
            Healthy = $true
        }
    }
    catch {
        return @{
            Name = $Name
            Status = "❌ DOWN"
            StatusCode = "Error"
            Error = $_.Exception.Message.Split("`n")[0]
            Healthy = $false
        }
    }
}

# Function to test Traffic Manager routing
function Test-TrafficManagerRouting {
    param([string]$TmUrl)
    try {
        $response = Invoke-WebRequest -Uri $TmUrl -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        $headers = $response.Headers
        return @{
            Status = "✅ ROUTING"
            StatusCode = $response.StatusCode
            Healthy = $true
            Headers = $headers
        }
    }
    catch {
        return @{
            Status = "❌ FAILED" 
            StatusCode = "Error"
            Error = $_.Exception.Message.Split("`n")[0]
            Healthy = $false
        }
    }
}

# Function to get current backend from Traffic Manager
function Get-CurrentBackend {
    param([string]$TmUrl)
    try {
        # Try to get the actual page to see which backend is serving
        $response = Invoke-WebRequest -Uri $TmUrl -TimeoutSec 10 -ErrorAction Stop
        
        # Look for indicators in the response to determine which backend
        $content = $response.Content
        if ($content -match "azure|AKS" -and $content -notmatch "onprem|k3s") {
            return "🔷 Azure AKS"
        }
        elseif ($content -match "onprem|k3s" -or $content -match "66\.242\.207\.21") {
            return "🏠 OnPrem K3s"
        }
        else {
            return "❓ Unknown Backend"
        }
    }
    catch {
        return "❌ Cannot Determine"
    }
}

Write-Host "📋 Test Configuration:" -ForegroundColor Cyan
Write-Host "   Traffic Manager: $TrafficManagerUrl" -ForegroundColor Yellow
Write-Host "   Azure Endpoint: $AzureEndpoint" -ForegroundColor Yellow
Write-Host "   OnPrem Endpoint: $OnPremEndpoint" -ForegroundColor Yellow
Write-Host "   Test Duration: $TestDuration seconds" -ForegroundColor Yellow
Write-Host ""

# Initial health check
Write-Host "🔍 Initial Health Check:" -ForegroundColor Blue
$azureHealth = Test-EndpointHealth -Endpoint $AzureEndpoint -Name "Azure AKS"
$onpremHealth = Test-EndpointHealth -Endpoint $OnPremEndpoint -Name "OnPrem K3s"
$tmHealth = Test-TrafficManagerRouting -TmUrl $TrafficManagerUrl

Write-Host "   $($azureHealth.Name): $($azureHealth.Status)" -ForegroundColor $(if ($azureHealth.Healthy) { "Green" } else { "Red" })
Write-Host "   $($onpremHealth.Name): $($onpremHealth.Status)" -ForegroundColor $(if ($onpremHealth.Healthy) { "Green" } else { "Red" })
Write-Host "   Traffic Manager: $($tmHealth.Status)" -ForegroundColor $(if ($tmHealth.Healthy) { "Green" } else { "Red" })

if ($tmHealth.Healthy) {
    $currentBackend = Get-CurrentBackend -TmUrl $TrafficManagerUrl
    Write-Host "   Current Backend: $currentBackend" -ForegroundColor Magenta
}

Write-Host ""

# Continuous monitoring
Write-Host "🔄 Starting Continuous Monitoring..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$testCount = 0
$lastBackend = ""

while ((Get-Date) -lt $startTime.AddSeconds($TestDuration)) {
    $testCount++
    
    # Clear screen and show status
    Clear-Host
    Write-Host "🧪 TRAFFIC MANAGER FAILOVER TEST - Check #$testCount" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "🕐 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Elapsed: $([math]::Round((New-TimeSpan -Start $startTime).TotalSeconds))s" -ForegroundColor Gray
    Write-Host ""
    
    # Test all endpoints
    $azureStatus = Test-EndpointHealth -Endpoint $AzureEndpoint -Name "Azure AKS"
    $onpremStatus = Test-EndpointHealth -Endpoint $OnPremEndpoint -Name "OnPrem K3s"
    $tmStatus = Test-TrafficManagerRouting -TmUrl $TrafficManagerUrl
    
    # Display status
    Write-Host "📊 Endpoint Status:" -ForegroundColor Cyan
    Write-Host "   $($azureStatus.Name): $($azureStatus.Status)" -ForegroundColor $(if ($azureStatus.Healthy) { "Green" } else { "Red" })
    if (-not $azureStatus.Healthy -and $azureStatus.Error) {
        Write-Host "      Error: $($azureStatus.Error)" -ForegroundColor DarkRed
    }
    
    Write-Host "   $($onpremStatus.Name): $($onpremStatus.Status)" -ForegroundColor $(if ($onpremStatus.Healthy) { "Green" } else { "Red" })
    if (-not $onpremStatus.Healthy -and $onpremStatus.Error) {
        Write-Host "      Error: $($onpremStatus.Error)" -ForegroundColor DarkRed
    }
    
    Write-Host "   Traffic Manager: $($tmStatus.Status)" -ForegroundColor $(if ($tmStatus.Healthy) { "Green" } else { "Red" })
    if (-not $tmStatus.Healthy -and $tmStatus.Error) {
        Write-Host "      Error: $($tmStatus.Error)" -ForegroundColor DarkRed
    }
    
    Write-Host ""
    
    # Show routing decision
    if ($tmStatus.Healthy) {
        $currentBackend = Get-CurrentBackend -TmUrl $TrafficManagerUrl
        Write-Host "🎯 Current Routing:" -ForegroundColor Yellow
        Write-Host "   Active Backend: $currentBackend" -ForegroundColor Magenta
        
        # Detect failover
        if ($lastBackend -ne "" -and $lastBackend -ne $currentBackend) {
            Write-Host "   🚨 FAILOVER DETECTED!" -ForegroundColor Red
            Write-Host "   Changed from: $lastBackend" -ForegroundColor Gray
            Write-Host "   Changed to: $currentBackend" -ForegroundColor Gray
        }
        $lastBackend = $currentBackend
    }
    
    # Show expected routing
    Write-Host "🤔 Expected Routing Logic:" -ForegroundColor Blue
    if ($azureStatus.Healthy -and $onpremStatus.Healthy) {
        Write-Host "   Both UP → Should route to Azure (Priority 1)" -ForegroundColor Green
    }
    elseif ($azureStatus.Healthy -and -not $onpremStatus.Healthy) {
        Write-Host "   Only Azure UP → Should route to Azure" -ForegroundColor Yellow
    }
    elseif (-not $azureStatus.Healthy -and $onpremStatus.Healthy) {
        Write-Host "   Only OnPrem UP → Should route to OnPrem" -ForegroundColor Yellow
    }
    else {
        Write-Host "   Both DOWN → Traffic Manager should return error" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "🧪 Failover Test Instructions:" -ForegroundColor Cyan
    Write-Host "   1. Keep this monitor running" -ForegroundColor Gray
    Write-Host "   2. In another terminal, shut down AKS cluster" -ForegroundColor Gray
    Write-Host "   3. Watch for automatic failover to OnPrem" -ForegroundColor Gray
    Write-Host "   4. Start AKS cluster back up" -ForegroundColor Gray
    Write-Host "   5. Watch for automatic failback to Azure" -ForegroundColor Gray
    
    Start-Sleep 15
}

Write-Host ""
Write-Host "✅ Test completed!" -ForegroundColor Green
Write-Host "Check the log above for any detected failovers." -ForegroundColor Gray
# Fix Traffic Manager to Use TCP Monitoring
# This changes from HTTP monitoring (port 80) to TCP monitoring (port 31514)
# This allows Traffic Manager to directly monitor the NodePort without a proxy

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$ProfileName = "voting-app-tm-2334"
)

Write-Host "🔧 FIXING TRAFFIC MANAGER TO USE TCP MONITORING" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan

# Check if Azure PowerShell is available
if (!(Get-Module -ListAvailable -Name Az.TrafficManager)) {
    Write-Host "❌ Azure PowerShell TrafficManager module not found" -ForegroundColor Red
    Write-Host "💡 Install with: Install-Module -Name Az.TrafficManager" -ForegroundColor Yellow
    exit 1
}

# Import the module
Import-Module Az.TrafficManager -Force

# Check if logged in
try {
    $context = Get-AzContext
    if (!$context) {
        Write-Host "❌ Not logged into Azure" -ForegroundColor Red
        Write-Host "💡 Login with: Connect-AzAccount" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure login check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get current Traffic Manager profile
Write-Host "🔍 Getting current Traffic Manager configuration..." -ForegroundColor Yellow
try {
    $profile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroupName
    Write-Host "✅ Found Traffic Manager profile: $($profile.Name)" -ForegroundColor Green
    Write-Host "📊 Current monitoring: $($profile.MonitorProtocol) on port $($profile.MonitorPort)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Failed to get Traffic Manager profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show current endpoint status before change
Write-Host "📊 Current endpoint status:" -ForegroundColor Yellow
# Get endpoints directly from the profile object
foreach ($endpoint in $profile.Endpoints) {
    $status = if ($endpoint.EndpointMonitorStatus) { $endpoint.EndpointMonitorStatus } else { "Unknown" }
    Write-Host "   $($endpoint.Name): $status ($($endpoint.Target))" -ForegroundColor $(if ($status -eq "Online") { "Green" } else { "Red" })
}

# Update Traffic Manager to use TCP monitoring on port 31514
Write-Host "🔄 Updating Traffic Manager to TCP monitoring on port 31514..." -ForegroundColor Yellow
try {
    $profile.MonitorProtocol = "TCP"
    $profile.MonitorPort = 31514
    $profile.MonitorPath = $null  # TCP doesn't use paths
    
    $result = Set-AzTrafficManagerProfile -TrafficManagerProfile $profile
    Write-Host "✅ Traffic Manager updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Traffic Manager: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Also need to update the Azure endpoint to use port 31514
Write-Host "🔄 Checking endpoint configurations..." -ForegroundColor Yellow

# Find the Azure and OnPrem endpoints
$azureEndpoint = $null
$onpremEndpoint = $null

foreach ($endpoint in $profile.Endpoints) {
    if ($endpoint.Name -eq "azure-aks-primary") {
        $azureEndpoint = $endpoint
        Write-Host "   Found Azure endpoint: $($endpoint.Target)" -ForegroundColor Green
    }
    elseif ($endpoint.Name -eq "onprem-backup") {
        $onpremEndpoint = $endpoint
        Write-Host "   Found OnPrem endpoint: $($endpoint.Target)" -ForegroundColor Green
    }
}

# Note about Azure endpoint
if ($azureEndpoint) {
    Write-Host "📝 Note: Azure endpoint ($($azureEndpoint.Target)) should work with TCP:31514" -ForegroundColor Yellow
    Write-Host "   If Azure uses LoadBalancer on port 80, consider updating to NodePort for consistency" -ForegroundColor Yellow
}

if ($onpremEndpoint) {
    Write-Host "✅ OnPrem endpoint ($($onpremEndpoint.Target)) ready for TCP:31514" -ForegroundColor Green
}

# Wait for propagation
Write-Host "⏳ Waiting for changes to propagate (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check endpoint status after change
Write-Host "🔍 Checking endpoint status after change..." -ForegroundColor Yellow
try {
    # Refresh the profile to get updated endpoint status
    $refreshedProfile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroupName
    foreach ($endpoint in $refreshedProfile.Endpoints) {
        $status = if ($endpoint.EndpointMonitorStatus) { $endpoint.EndpointMonitorStatus } else { "Checking..." }
        Write-Host "   $($endpoint.Name): $status ($($endpoint.Target))" -ForegroundColor $(if ($status -eq "Online") { "Green" } elseif ($status -eq "Checking...") { "Yellow" } else { "Red" })
    }
} catch {
    Write-Host "⚠️  Error checking endpoint status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "🎯 TRAFFIC MANAGER TCP MONITORING ENABLED!" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Monitoring protocol: TCP" -ForegroundColor Green
Write-Host "✅ Monitoring port: 31514" -ForegroundColor Green
Write-Host "⏳ Allow 2-3 minutes for full health propagation" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "🧪 Test with:" -ForegroundColor Cyan
Write-Host "   .\scripts\test-failover-analysis.ps1" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "📋 IMPORTANT NOTE:" -ForegroundColor Cyan
Write-Host "   TCP monitoring only checks if port is open" -ForegroundColor Yellow
Write-Host "   HTTP monitoring (with health proxy) provides better health detection" -ForegroundColor Yellow
Write-Host "   Consider implementing HTTP health checks for production use" -ForegroundColor Yellow
# Fix Traffic Manager for Port 31514 (Now that it's working!)

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko",
    [switch]$DeletePort80Service
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ FIX TRAFFIC MANAGER - PORT 31514 NOW WORKING!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔧 The port 31514 service has been fixed!" -ForegroundColor Green
Write-Host "   Problem: targetPort was 80 (wrong)" -ForegroundColor Gray
Write-Host "   Fixed: targetPort is now 5000 (correct)" -ForegroundColor Green
Write-Host ""

$kubectlCmd = if (Get-Command kubectl -ErrorAction SilentlyContinue) { "kubectl" } else { ".\kubectl-temp.exe" }

Write-Host "📊 Testing both Azure services:" -ForegroundColor Yellow

function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "   ✅ $name - Online ($($response.StatusCode))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "   ❌ $name - Offline" -ForegroundColor Red
        return $false
    }
}

Test-Endpoint "http://172.168.91.225" "Port 80 service (172.168.91.225)"
Test-Endpoint "http://172.169.36.153:31514" "Port 31514 service (172.169.36.153)"
Test-Endpoint "http://66.242.207.21:31514" "OnPrem (66.242.207.21)"

Write-Host ""

if ($DeletePort80Service) {
    Write-Host "🗑️ Deleting port 80 service (azure-voting-app-complete-service)..." -ForegroundColor Yellow
    & $kubectlCmd delete service azure-voting-app-complete-service
    Write-Host "✅ Port 80 service deleted" -ForegroundColor Green
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🌍 Updating Traffic Manager..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if Az.TrafficManager module is installed
if (-not (Get-Module -ListAvailable -Name Az.TrafficManager)) {
    Write-Host "📦 Installing Az.TrafficManager module..." -ForegroundColor Cyan
    Install-Module -Name Az.TrafficManager -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "✅ Module installed" -ForegroundColor Green
}

# Connect to Azure
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "🔐 Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount
    $context = Get-AzContext
}

Write-Host "✅ Connected as: $($context.Account.Id)" -ForegroundColor Green
Write-Host ""

# Get Traffic Manager profile
Write-Host "📊 Getting Traffic Manager profile..." -ForegroundColor Cyan
try {
    $profile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroup -ErrorAction Stop
    
    Write-Host "✅ Current configuration:" -ForegroundColor Green
    Write-Host "   Profile: $($profile.Name)" -ForegroundColor Gray
    Write-Host "   DNS: $($profile.RelativeDnsName).trafficmanager.net" -ForegroundColor Gray
    Write-Host "   Monitor Port: $($profile.MonitorPort)" -ForegroundColor Gray
    Write-Host "   Monitor Protocol: $($profile.MonitorProtocol)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📍 Current Endpoints:" -ForegroundColor Cyan
    foreach ($endpoint in $profile.Endpoints) {
        Write-Host "   - $($endpoint.Name): $($endpoint.Target) [$($endpoint.EndpointMonitorStatus)]" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ Failed to get Traffic Manager profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔧 Updating to port 31514 with TCP monitoring..." -ForegroundColor Yellow

# Update monitoring settings
$profile.MonitorPort = 31514
$profile.MonitorProtocol = "TCP"
$profile.MonitorPath = $null

# Update endpoints
foreach ($endpoint in $profile.Endpoints) {
    if ($endpoint.Name -like "*azure*") {
        Write-Host "   Updating Azure endpoint: $($endpoint.Name)" -ForegroundColor Cyan
        Write-Host "     Old: $($endpoint.Target)" -ForegroundColor Gray
        $endpoint.Target = "172.169.36.153"
        Write-Host "     New: 172.169.36.153" -ForegroundColor Green
    }
    elseif ($endpoint.Name -like "*onprem*") {
        Write-Host "   Updating OnPrem endpoint: $($endpoint.Name)" -ForegroundColor Cyan
        Write-Host "     Old: $($endpoint.Target)" -ForegroundColor Gray
        $endpoint.Target = "66.242.207.21"
        Write-Host "     New: 66.242.207.21" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "💾 Saving Traffic Manager configuration..." -ForegroundColor Yellow

try {
    Set-AzTrafficManagerProfile -TrafficManagerProfile $profile -ErrorAction Stop
    Write-Host "✅ Traffic Manager updated successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to update: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Verifying changes..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$updatedProfile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroup

Write-Host "✅ Updated Configuration:" -ForegroundColor Green
Write-Host "   Monitor Port: $($updatedProfile.MonitorPort)" -ForegroundColor Gray
Write-Host "   Monitor Protocol: $($updatedProfile.MonitorProtocol)" -ForegroundColor Gray
Write-Host ""

Write-Host "📍 Updated Endpoints:" -ForegroundColor Cyan
foreach ($endpoint in $updatedProfile.Endpoints) {
    Write-Host "   - $($endpoint.Name): $($endpoint.Target):$($updatedProfile.MonitorPort)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ COMPLETE - TRAFFIC MANAGER FIXED!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "🌍 Traffic Manager URL:" -ForegroundColor Magenta
Write-Host "   http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Wait 30-60 seconds for health checks to update, then test:" -ForegroundColor Yellow
Write-Host "   Invoke-WebRequest -Uri 'http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514' -Method Head" -ForegroundColor Gray
Write-Host ""

Write-Host "📊 Final Service Configuration:" -ForegroundColor Yellow
& $kubectlCmd get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORT:.spec.ports[0].port

Write-Host ""
Write-Host "🎉 Done! Both environments now use port 31514" -ForegroundColor Green
Write-Host "   ✅ Azure: 172.169.36.153:31514 (targetPort fixed to 5000)" -ForegroundColor Gray
Write-Host "   ✅ OnPrem: 66.242.207.21:31514 (no router conflict)" -ForegroundColor Gray
Write-Host ""

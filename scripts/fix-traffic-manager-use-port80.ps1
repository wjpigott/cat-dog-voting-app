# Fix Traffic Manager to Use Port 80 (Working Azure Service)
# This uses your working Azure service at 172.168.91.225:80

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko"
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 FIX TRAFFIC MANAGER - USE PORT 80" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "This will configure Traffic Manager to use:" -ForegroundColor Yellow
Write-Host "  ✅ Azure: 172.168.91.225:80 (WORKING)" -ForegroundColor Green
Write-Host "  ⚠️  OnPrem: YOUR_ONPREM_IP:80 (YOU NEED TO CHANGE THIS)" -ForegroundColor Yellow
Write-Host ""

Write-Host "⚠️ WARNING: You need to change your OnPrem to port 80 first!" -ForegroundColor Red
Write-Host ""
Write-Host "To change OnPrem (run on your OnPrem K3s machine):" -ForegroundColor Cyan
Write-Host "  1. Find your service name:" -ForegroundColor White
Write-Host "     kubectl get services" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Either use NodePort 30080 with router forwarding:" -ForegroundColor White
Write-Host "     kubectl patch service YOUR-SERVICE-NAME --type='json' -p='[{`"op`":`"replace`",`"path`":`"/spec/ports/0/nodePort`",`"value`":30080}]'" -ForegroundColor Gray
Write-Host "     Then configure your router to forward port 80 to OnPrem_IP:30080" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Or try NodePort 80 directly (may require privileged access):" -ForegroundColor White
Write-Host "     kubectl patch service YOUR-SERVICE-NAME --type='json' -p='[{`"op`":`"replace`",`"path`":`"/spec/ports/0/nodePort`",`"value`":80}]'" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Have you changed OnPrem to port 80? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host ""
    Write-Host "❌ Please change OnPrem to port 80 first, then run this script again" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "🌍 Updating Traffic Manager..." -ForegroundColor Yellow
Write-Host ""

# Check if Az.TrafficManager module is installed
if (-not (Get-Module -ListAvailable -Name Az.TrafficManager)) {
    Write-Host "📦 Installing Az.TrafficManager module..." -ForegroundColor Cyan
    Install-Module -Name Az.TrafficManager -Force -AllowClobber -Scope CurrentUser
}

# Connect to Azure
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "🔐 Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount
}

# Get Traffic Manager profile
Write-Host "📊 Getting Traffic Manager profile..." -ForegroundColor Cyan
$profile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroup

Write-Host "✅ Current configuration:" -ForegroundColor Green
Write-Host "   Monitor Port: $($profile.MonitorPort)" -ForegroundColor Gray
Write-Host "   Monitor Protocol: $($profile.MonitorProtocol)" -ForegroundColor Gray
Write-Host ""

# Update settings
Write-Host "🔧 Updating to port 80 with HTTP monitoring..." -ForegroundColor Yellow
$profile.MonitorPort = 80
$profile.MonitorProtocol = "HTTP"
$profile.MonitorPath = "/health"

# Update endpoints
foreach ($endpoint in $profile.Endpoints) {
    if ($endpoint.Name -like "*azure*") {
        Write-Host "   Updating Azure endpoint: $($endpoint.Name)" -ForegroundColor Cyan
        Write-Host "     Old: $($endpoint.Target)" -ForegroundColor Gray
        $endpoint.Target = "172.168.91.225"
        Write-Host "     New: 172.168.91.225" -ForegroundColor Green
    }
    elseif ($endpoint.Name -like "*onprem*") {
        Write-Host "   Updating OnPrem endpoint: $($endpoint.Name)" -ForegroundColor Cyan
        Write-Host "     Old: $($endpoint.Target)" -ForegroundColor Gray
        $endpoint.Target = $OnPremIP
        Write-Host "     New: $OnPremIP" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "💾 Saving changes..." -ForegroundColor Yellow

Set-AzTrafficManagerProfile -TrafficManagerProfile $profile

Write-Host "✅ Traffic Manager updated!" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ COMPLETE - Traffic Manager Now Uses Port 80" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "🌍 Traffic Manager URL: http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor Magenta
Write-Host ""
Write-Host "⏳ Wait 30-60 seconds for health checks to update, then test:" -ForegroundColor Yellow
Write-Host "   Invoke-WebRequest -Uri 'http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net' -Method Head" -ForegroundColor Gray
Write-Host ""

# Test endpoints
Write-Host "🔍 Testing endpoints now..." -ForegroundColor Yellow

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

Test-Endpoint "http://172.168.91.225" "Azure (port 80)"
Test-Endpoint "http://$OnPremIP" "OnPrem (port 80)"

Write-Host ""

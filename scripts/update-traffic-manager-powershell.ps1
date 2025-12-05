# Update Traffic Manager Using Azure PowerShell Module
# This avoids the permission issues with Azure CLI

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko",
    [string]$AzureIP = "172.168.91.225",  # Better version on port 80
    [string]$OnPremIP = "66.242.207.21",
    [int]$Port = 80,  # Change to 31514 if using Option B
    [ValidateSet("HTTP", "TCP")]
    [string]$Protocol = "HTTP"  # Change to TCP if using port 31514
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🌍 TRAFFIC MANAGER UPDATE - PowerShell Module" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Az.TrafficManager module is installed
Write-Host "📦 Checking Azure PowerShell modules..." -ForegroundColor Yellow

if (-not (Get-Module -ListAvailable -Name Az.TrafficManager)) {
    Write-Host "Installing Az.TrafficManager module..." -ForegroundColor Cyan
    try {
        Install-Module -Name Az.TrafficManager -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Host "✅ Module installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Az.TrafficManager module available" -ForegroundColor Green
Write-Host ""

# Step 2: Connect to Azure
Write-Host "🔐 Connecting to Azure..." -ForegroundColor Yellow

try {
    $context = Get-AzContext -ErrorAction SilentlyContinue
    
    if (-not $context) {
        Write-Host "Please sign in to Azure..." -ForegroundColor Cyan
        Connect-AzAccount
        $context = Get-AzContext
    }
    
    Write-Host "✅ Connected as: $($context.Account.Id)" -ForegroundColor Green
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Failed to connect to Azure: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Get current Traffic Manager profile
Write-Host "📊 Getting Traffic Manager profile..." -ForegroundColor Yellow

try {
    $profile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroup -ErrorAction Stop
    
    Write-Host "✅ Profile found: $($profile.Name)" -ForegroundColor Green
    Write-Host "   DNS: $($profile.RelativeDnsName).trafficmanager.net" -ForegroundColor Gray
    Write-Host "   Current Monitor Port: $($profile.MonitorPort)" -ForegroundColor Gray
    Write-Host "   Current Monitor Protocol: $($profile.MonitorProtocol)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📍 Current Endpoints:" -ForegroundColor Cyan
    foreach ($endpoint in $profile.Endpoints) {
        Write-Host "   - $($endpoint.Name): $($endpoint.Target):$($profile.MonitorPort) [$($endpoint.EndpointMonitorStatus)]" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ Failed to get Traffic Manager profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Update monitoring settings
Write-Host "🔧 Updating Traffic Manager configuration..." -ForegroundColor Yellow
Write-Host "   New Port: $Port" -ForegroundColor Gray
Write-Host "   New Protocol: $Protocol" -ForegroundColor Gray
Write-Host ""

$profile.MonitorPort = $Port
$profile.MonitorProtocol = $Protocol

if ($Protocol -eq "HTTP") {
    $profile.MonitorPath = "/health"
    Write-Host "   Monitor Path: /health" -ForegroundColor Gray
}

# Step 5: Update endpoints
Write-Host "📍 Updating endpoints..." -ForegroundColor Yellow

# Find and update Azure endpoint
$azureEndpoint = $profile.Endpoints | Where-Object { $_.Name -like "*azure*" }
if ($azureEndpoint) {
    Write-Host "   Updating Azure endpoint: $($azureEndpoint.Name)" -ForegroundColor Cyan
    Write-Host "     Old Target: $($azureEndpoint.Target)" -ForegroundColor Gray
    Write-Host "     New Target: $AzureIP" -ForegroundColor Green
    $azureEndpoint.Target = $AzureIP
}

# Find and update OnPrem endpoint
$onpremEndpoint = $profile.Endpoints | Where-Object { $_.Name -like "*onprem*" }
if ($onpremEndpoint) {
    Write-Host "   Updating OnPrem endpoint: $($onpremEndpoint.Name)" -ForegroundColor Cyan
    Write-Host "     Old Target: $($onpremEndpoint.Target)" -ForegroundColor Gray
    Write-Host "     New Target: $OnPremIP" -ForegroundColor Green
    $onpremEndpoint.Target = $OnPremIP
}

Write-Host ""

# Step 6: Save changes
Write-Host "💾 Saving Traffic Manager profile..." -ForegroundColor Yellow

try {
    Set-AzTrafficManagerProfile -TrafficManagerProfile $profile -ErrorAction Stop
    Write-Host "✅ Traffic Manager updated successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to update profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 7: Verify changes
Write-Host "🔍 Verifying changes..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$updatedProfile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroup

Write-Host "✅ Updated Configuration:" -ForegroundColor Green
Write-Host "   Monitor Port: $($updatedProfile.MonitorPort)" -ForegroundColor Gray
Write-Host "   Monitor Protocol: $($updatedProfile.MonitorProtocol)" -ForegroundColor Gray
if ($updatedProfile.MonitorPath) {
    Write-Host "   Monitor Path: $($updatedProfile.MonitorPath)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "📍 Updated Endpoints:" -ForegroundColor Cyan
foreach ($endpoint in $updatedProfile.Endpoints) {
    Write-Host "   - $($endpoint.Name): $($endpoint.Target):$($updatedProfile.MonitorPort)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ TRAFFIC MANAGER UPDATE COMPLETE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$tmUrl = "http://$($updatedProfile.RelativeDnsName).trafficmanager.net"
if ($Port -ne 80) {
    $tmUrl += ":$Port"
}

Write-Host "🌍 Traffic Manager URL: $tmUrl" -ForegroundColor Magenta
Write-Host ""

Write-Host "⏳ Note: It may take 30-60 seconds for health checks to update" -ForegroundColor Yellow
Write-Host ""

# Step 8: Test endpoints
Write-Host "🔍 Testing endpoints..." -ForegroundColor Yellow

function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "   ✅ $name - Online ($($response.StatusCode))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "   ❌ $name - Offline ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

$azureUrl = "http://$AzureIP"
if ($Port -ne 80) { $azureUrl += ":$Port" }

$onpremUrl = "http://$OnPremIP"
if ($Port -ne 80) { $onpremUrl += ":$Port" }

Test-Endpoint $azureUrl "Azure endpoint"
Test-Endpoint $onpremUrl "OnPrem endpoint"
Test-Endpoint $tmUrl "Traffic Manager"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 All Done!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

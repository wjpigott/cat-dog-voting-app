# Deploy OnPrem Health Proxy for Traffic Manager
# This script deploys the NGINX health proxy to enable Traffic Manager health monitoring

param(
    [Parameter(Mandatory=$false)]
    [string]$OnPremContext = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$KubeconfigPath = ""
)

Write-Host "🚀 DEPLOYING ONPREM HEALTH PROXY FOR TRAFFIC MANAGER" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor Cyan

# Check if kubectl is available
if (!(Get-Command ".\kubectl.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl.exe not found in current directory" -ForegroundColor Red
    exit 1
}

# Set kubeconfig if provided
if ($KubeconfigPath) {
    $env:KUBECONFIG = $KubeconfigPath
    Write-Host "🔧 Using kubeconfig: $KubeconfigPath" -ForegroundColor Yellow
}

# Switch to on-premises context
Write-Host "🔄 Switching to OnPrem context: $OnPremContext" -ForegroundColor Yellow
$contextResult = .\kubectl.exe config use-context $OnPremContext 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to switch to context '$OnPremContext'" -ForegroundColor Red
    Write-Host "Available contexts:" -ForegroundColor Yellow
    .\kubectl.exe config get-contexts
    exit 1
}

# Check cluster connectivity
Write-Host "🔍 Testing cluster connectivity..." -ForegroundColor Yellow
$nodeResult = .\kubectl.exe get nodes 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cannot connect to OnPrem cluster" -ForegroundColor Red
    Write-Host $nodeResult -ForegroundColor Red
    exit 1
}
Write-Host "✅ Connected to OnPrem cluster" -ForegroundColor Green

# Check if health proxy already exists
Write-Host "🔍 Checking if health proxy already exists..." -ForegroundColor Yellow
$existingProxy = .\kubectl.exe get deployment traffic-manager-health-proxy -n default 2>$null
if ($existingProxy) {
    Write-Host "⚠️  Health proxy already exists. Updating..." -ForegroundColor Yellow
    .\kubectl.exe delete deployment traffic-manager-health-proxy -n default
    .\kubectl.exe delete service traffic-manager-health-proxy -n default
    Start-Sleep -Seconds 5
}

# Deploy the health proxy
Write-Host "🚀 Deploying Traffic Manager health proxy..." -ForegroundColor Yellow
$deployResult = .\kubectl.exe apply -f .\traffic-manager-health-proxy.yaml 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to deploy health proxy" -ForegroundColor Red
    Write-Host $deployResult -ForegroundColor Red
    exit 1
}
Write-Host "✅ Health proxy deployed successfully" -ForegroundColor Green

# Wait for deployment to be ready
Write-Host "⏳ Waiting for health proxy to be ready..." -ForegroundColor Yellow
$timeout = 60
$elapsed = 0
do {
    $readyPods = .\kubectl.exe get pods -l app=traffic-manager-health-proxy -o jsonpath='{.items[*].status.phase}' 2>$null
    if ($readyPods -eq "Running") {
        Write-Host "✅ Health proxy is running!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "⏳ Still waiting... ($elapsed/$timeout seconds)" -ForegroundColor Yellow
} while ($elapsed -lt $timeout)

if ($elapsed -ge $timeout) {
    Write-Host "⚠️  Timeout waiting for health proxy. Checking status..." -ForegroundColor Yellow
    .\kubectl.exe get pods -l app=traffic-manager-health-proxy
    .\kubectl.exe describe pods -l app=traffic-manager-health-proxy
}

# Test the health proxy locally
Write-Host "🧪 Testing health proxy locally..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://66.242.207.21" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Health proxy responding on port 80: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Health proxy test failed (may take a few minutes): $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "🎯 DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "═══════════════════════" -ForegroundColor Cyan
Write-Host "✅ Health proxy deployed to OnPrem cluster" -ForegroundColor Green
Write-Host "🔄 Traffic Manager will detect OnPrem health in 2-3 minutes" -ForegroundColor Yellow
Write-Host "🧪 Test with: .\scripts\test-failover-analysis.ps1" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "🌐 Traffic Manager URL: http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor Cyan
Write-Host "🏠 OnPrem Direct: http://66.242.207.21:31514" -ForegroundColor Yellow
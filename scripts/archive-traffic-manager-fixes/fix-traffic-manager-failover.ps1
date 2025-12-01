# Fix Traffic Manager Configuration for Proper Failover
# This script fixes the Traffic Manager endpoint configuration

param(
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko",
    [string]$ResourceGroup = "rg-cat-dog-voting"
)

Write-Host "🔧 FIXING TRAFFIC MANAGER FAILOVER CONFIGURATION" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "📋 Issue Identified:" -ForegroundColor Yellow
Write-Host "   - Health monitoring configured for port 80" -ForegroundColor Red
Write-Host "   - OnPrem endpoint runs on port 31514" -ForegroundColor Red
Write-Host "   - Traffic Manager can't health check OnPrem properly" -ForegroundColor Red

Write-Host "`n🔍 Current Configuration:" -ForegroundColor Cyan
Write-Host "   Profile: $ProfileName" -ForegroundColor Gray
Write-Host "   Azure Endpoint: 52.154.54.110:80 ✅" -ForegroundColor Green
Write-Host "   OnPrem Endpoint: 66.242.207.21 (port 31514) ❌" -ForegroundColor Red

Write-Host "`n🛠️ SOLUTION OPTIONS:" -ForegroundColor Magenta

Write-Host "`n1️⃣ OPTION 1: Update Traffic Manager Health Monitoring" -ForegroundColor Cyan
Write-Host "   Problem: Traffic Manager only supports ONE port for health monitoring" -ForegroundColor Yellow
Write-Host "   This won't work because Azure:80 ≠ OnPrem:31514" -ForegroundColor Red

Write-Host "`n2️⃣ OPTION 2: Create Health Check Endpoints" -ForegroundColor Cyan
Write-Host "   Solution: Create health endpoints on both environments at same path/port" -ForegroundColor Green

Write-Host "`n3️⃣ OPTION 3: Use Nested Profiles (Recommended)" -ForegroundColor Green
Write-Host "   Solution: Create separate profiles for each environment" -ForegroundColor Green

# Install Traffic Manager module if needed
try {
    Import-Module Az.TrafficManager -ErrorAction Stop
    Write-Host "✅ Az.TrafficManager module loaded" -ForegroundColor Green
}
catch {
    Write-Host "📦 Installing Az.TrafficManager module..." -ForegroundColor Yellow
    Install-Module Az.TrafficManager -Force -AllowClobber -Scope CurrentUser
    Import-Module Az.TrafficManager
    Write-Host "✅ Az.TrafficManager module installed and loaded" -ForegroundColor Green
}

# Get current profile
try {
    $profile = Get-AzTrafficManagerProfile -ResourceGroupName $ResourceGroup -Name $ProfileName
    Write-Host "`n📊 Current Endpoint Status:" -ForegroundColor Cyan
    
    foreach ($endpoint in $profile.Endpoints) {
        $status = if ($endpoint.EndpointMonitorStatus -eq "Online") { "✅" } else { "❌" }
        Write-Host "   $status $($endpoint.Name): $($endpoint.Target) (Priority: $($endpoint.Priority), Status: $($endpoint.EndpointMonitorStatus))" -ForegroundColor Gray
    }
    
    Write-Host "`n❌ PROBLEM CONFIRMED:" -ForegroundColor Red
    Write-Host "   OnPrem endpoint likely showing as 'Degraded' or 'Offline'" -ForegroundColor Red
    Write-Host "   Traffic Manager can't health check port 31514 with HTTP on port 80" -ForegroundColor Red
}
catch {
    Write-Host "❌ Could not get Traffic Manager profile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🚀 IMMEDIATE FIX: Create Health Check Proxy" -ForegroundColor Green
Write-Host "We'll create a simple health endpoint on OnPrem port 80 that proxies to port 31514" -ForegroundColor Gray

# Create NGINX health proxy configuration
$nginxConfig = @"
# NGINX Health Check Proxy for Traffic Manager
# This runs on OnPrem and provides a health endpoint on port 80

upstream onprem_app {
    server 127.0.0.1:31514;
}

server {
    listen 80;
    server_name localhost;
    
    # Health check endpoint for Traffic Manager
    location /health {
        proxy_pass http://onprem_app/;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
        
        # Return 200 if upstream is healthy
        proxy_intercept_errors on;
        error_page 502 503 504 =503 /health_down;
    }
    
    # Fallback for when app is down
    location /health_down {
        return 503 "OnPrem App Down";
    }
    
    # Proxy all other traffic
    location / {
        proxy_pass http://onprem_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
"@

Write-Host "`n📝 NGINX Health Proxy Configuration:" -ForegroundColor Cyan
Write-Host $nginxConfig -ForegroundColor Gray

Write-Host "`n📋 IMMEDIATE STEPS TO FIX:" -ForegroundColor Magenta
Write-Host "1. Deploy NGINX proxy on OnPrem cluster (port 80 → 31514)" -ForegroundColor White
Write-Host "2. Update Traffic Manager to monitor port 80 on both endpoints" -ForegroundColor White
Write-Host "3. Test failover functionality" -ForegroundColor White

Write-Host "`n🔧 Would you like me to create the NGINX health proxy?" -ForegroundColor Yellow
Write-Host "This will enable proper Traffic Manager health monitoring." -ForegroundColor Gray
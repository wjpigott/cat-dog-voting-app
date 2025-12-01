# Fix Traffic Manager OnPrem Endpoint Port
# Update the OnPrem endpoint to include port 31514

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko"
)

Write-Host "🔧 UPDATING TRAFFIC MANAGER ENDPOINT PORTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

# Import the module
Import-Module Az.TrafficManager -Force

# Get the Traffic Manager profile
try {
    $profile = Get-AzTrafficManagerProfile -Name $ProfileName -ResourceGroupName $ResourceGroupName
    Write-Host "✅ Found Traffic Manager profile: $($profile.Name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get Traffic Manager profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show current endpoints
Write-Host "📊 Current endpoints:" -ForegroundColor Yellow
foreach ($endpoint in $profile.Endpoints) {
    Write-Host "   $($endpoint.Name): $($endpoint.Target)" -ForegroundColor Gray
}

# Try to update the OnPrem endpoint to include port
Write-Host "🔄 Updating OnPrem endpoint to include port 31514..." -ForegroundColor Yellow
try {
    # Find the OnPrem endpoint
    $onpremEndpoint = $profile.Endpoints | Where-Object { $_.Name -eq "onprem-backup" }
    
    if ($onpremEndpoint) {
        Write-Host "   Current target: $($onpremEndpoint.Target)" -ForegroundColor Gray
        
        # Try updating the target to include port
        $onpremEndpoint.Target = "66.242.207.21:31514"
        
        # Save the profile
        $result = Set-AzTrafficManagerProfile -TrafficManagerProfile $profile
        Write-Host "✅ OnPrem endpoint updated to: 66.242.207.21:31514" -ForegroundColor Green
    } else {
        Write-Host "❌ OnPrem endpoint not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Failed to update endpoint: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "⚠️  Traffic Manager may not support ports in External Endpoints" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "🔧 ALTERNATIVE SOLUTIONS:" -ForegroundColor Cyan
    Write-Host "1. Router Port Forwarding: Forward port 80 → 31514 on your router" -ForegroundColor Yellow
    Write-Host "2. NGINX Health Proxy: Deploy proxy on K3s cluster" -ForegroundColor Yellow
    Write-Host "3. Change K3s Service: Use LoadBalancer type on port 80" -ForegroundColor Yellow
    exit 1
}

# Wait for propagation
Write-Host "⏳ Waiting for changes to propagate (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Test the updated endpoint
Write-Host "🧪 Testing updated Traffic Manager..." -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri "http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -Method HEAD -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Traffic Manager now working! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Still issues with Traffic Manager URL" -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "💡 Try direct access: http://66.242.207.21:31514" -ForegroundColor Cyan
}

Write-Host "" -ForegroundColor White
Write-Host "🎯 ENDPOINT UPDATE COMPLETE!" -ForegroundColor Cyan
Write-Host "════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ OnPrem target: 66.242.207.21:31514" -ForegroundColor Green
Write-Host "🧪 Test URL: http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor Yellow
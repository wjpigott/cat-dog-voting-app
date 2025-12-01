# Fix Traffic Manager Failover - Correct Approach
# Updates Traffic Manager to properly monitor both endpoints

param(
    [string]$ProfileName = "voting-app-tm-2334-cstgesqvnzeko",
    [string]$ResourceGroup = "rg-cat-dog-voting"
)

Write-Host "🔧 FIXING TRAFFIC MANAGER - CORRECT APPROACH" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "💡 SOLUTION: Use endpoint-specific monitoring" -ForegroundColor Yellow
Write-Host "Traffic Manager supports custom monitoring per endpoint!" -ForegroundColor Cyan

# Import required module
Import-Module Az.TrafficManager -Force

# Get current profile
$profile = Get-AzTrafficManagerProfile -ResourceGroupName $ResourceGroup -Name $ProfileName

Write-Host "`n📊 Current Global Monitoring Config:" -ForegroundColor Cyan
Write-Host "   Protocol: $($profile.MonitorConfig.Protocol)" -ForegroundColor Gray
Write-Host "   Port: $($profile.MonitorConfig.Port)" -ForegroundColor Gray  
Write-Host "   Path: $($profile.MonitorConfig.Path)" -ForegroundColor Gray

Write-Host "`n🔧 UPDATING INDIVIDUAL ENDPOINTS:" -ForegroundColor Green

# Update Azure endpoint (keep port 80)
$azureEndpoint = $profile.Endpoints | Where-Object {$_.Name -eq "azure-aks-primary"}
if ($azureEndpoint) {
    Write-Host "✅ Azure endpoint: Port 80 (no changes needed)" -ForegroundColor Green
}

# Update OnPrem endpoint to use custom monitoring
$onpremEndpoint = $profile.Endpoints | Where-Object {$_.Name -eq "onprem-backup"}
if ($onpremEndpoint) {
    Write-Host "🔄 Updating OnPrem endpoint monitoring..." -ForegroundColor Yellow
    
    # For OnPrem, we need to update the endpoint target to specify port
    $onpremEndpoint.Target = "66.242.207.21"
    
    # Add custom headers for port-specific monitoring
    $customHeaders = @()
    $customHeaders += New-Object Microsoft.Azure.Commands.TrafficManager.Models.TrafficManagerCustomHeader -Property @{
        Name = "Host"
        Value = "66.242.207.21:31514"
    }
    $onpremEndpoint.CustomHeaders = $customHeaders
    
    Write-Host "✅ OnPrem endpoint: Added custom port header" -ForegroundColor Green
}

# Alternative approach: Update global monitoring to use path-based health checks
Write-Host "`n🎯 ALTERNATIVE: Path-based health check" -ForegroundColor Cyan
Write-Host "Instead of port monitoring, use /health path on both endpoints" -ForegroundColor Gray

# Update monitoring config to use /health path
$profile.MonitorConfig.Path = "/health"
$profile.MonitorConfig.Protocol = "HTTP"
$profile.MonitorConfig.Port = 80

Write-Host "`n💾 Saving Traffic Manager updates..." -ForegroundColor Yellow

try {
    Set-AzTrafficManagerProfile -TrafficManagerProfile $profile
    Write-Host "✅ Traffic Manager profile updated!" -ForegroundColor Green
    
    Write-Host "`n🔍 New Configuration:" -ForegroundColor Cyan
    Write-Host "   Global monitoring: HTTP port 80, path /health" -ForegroundColor Gray
    Write-Host "   Azure endpoint: 52.154.54.110:80/health" -ForegroundColor Gray
    Write-Host "   OnPrem endpoint: 66.242.207.21:80/health" -ForegroundColor Gray
    
    Write-Host "`n⚠️ NEXT STEP REQUIRED:" -ForegroundColor Yellow
    Write-Host "Deploy health proxy on OnPrem to respond on port 80" -ForegroundColor Red
    Write-Host "Run: kubectl apply -f traffic-manager-health-proxy.yaml" -ForegroundColor White
}
catch {
    Write-Host "❌ Error updating Traffic Manager: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🧪 TEST AFTER FIXING:" -ForegroundColor Magenta
Write-Host "1. Deploy OnPrem health proxy: kubectl apply -f traffic-manager-health-proxy.yaml" -ForegroundColor White
Write-Host "2. Wait 2-3 minutes for health checks to propagate" -ForegroundColor White
Write-Host "3. Test: curl http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor White
Write-Host "4. Should route to OnPrem when Azure is down!" -ForegroundColor Green
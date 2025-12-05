# Troubleshoot and Fix Port 31514 Service

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 TROUBLESHOOT PORT 31514 SERVICE" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$kubectlCmd = if (Get-Command kubectl -ErrorAction SilentlyContinue) { "kubectl" } else { ".\kubectl-temp.exe" }

Write-Host "📊 Current service status:" -ForegroundColor Yellow
& $kubectlCmd get service voting-app-31514-lb
Write-Host ""

Write-Host "📋 Service details:" -ForegroundColor Yellow
& $kubectlCmd describe service voting-app-31514-lb
Write-Host ""

Write-Host "🔍 Checking if LoadBalancer IP is provisioned..." -ForegroundColor Yellow
$lbIP = (& $kubectlCmd get service voting-app-31514-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if ($lbIP) {
    Write-Host "✅ LoadBalancer IP is assigned: $lbIP" -ForegroundColor Green
} else {
    Write-Host "❌ LoadBalancer IP is not assigned yet" -ForegroundColor Red
    Write-Host "   This can take 2-5 minutes after cluster restart..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Testing connectivity..." -ForegroundColor Yellow

# Test with curl if available, otherwise skip
try {
    $response = Invoke-WebRequest -Uri "http://$lbIP`:31514" -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Service is responding on port 31514!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Port 31514 is working! You can use Option B (keep port 31514)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Service is not responding on port 31514" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🔧 POSSIBLE FIXES:" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "FIX 1: Check Azure NSG (Network Security Group) Rules" -ForegroundColor Cyan
    Write-Host "   Port 31514 might be blocked by firewall" -ForegroundColor White
    Write-Host "   1. Go to Azure Portal" -ForegroundColor Gray
    Write-Host "   2. Find your AKS cluster's NSG" -ForegroundColor Gray
    Write-Host "   3. Add inbound rule for port 31514" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "FIX 2: Recreate the Service" -ForegroundColor Cyan
    Write-Host "   Sometimes LoadBalancers get stuck after cluster restart" -ForegroundColor White
    Write-Host "   kubectl delete service voting-app-31514-lb" -ForegroundColor Gray
    Write-Host "   kubectl expose deployment azure-voting-app-complete --name=voting-app-31514-lb --type=LoadBalancer --port=31514 --target-port=80" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "FIX 3: Use Port 80 Instead (EASIER)" -ForegroundColor Cyan
    Write-Host "   Your port 80 service (172.168.91.225) is working perfectly" -ForegroundColor White
    Write-Host "   Just change OnPrem to port 80 and use that for Traffic Manager" -ForegroundColor Gray
    Write-Host "   Run: .\scripts\fix-traffic-manager-use-port80.ps1" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📋 RECOMMENDATION:" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Since 172.168.91.225:80 is working and 172.169.36.153:31514 is not," -ForegroundColor Yellow
Write-Host "I recommend using Port 80 for both endpoints." -ForegroundColor Yellow
Write-Host ""

Write-Host "Benefits of Port 80:" -ForegroundColor Cyan
Write-Host "  ✅ Standard HTTP port (no port number in URL)" -ForegroundColor Gray
Write-Host "  ✅ Already working on Azure" -ForegroundColor Gray
Write-Host "  ✅ Better HTTP health monitoring" -ForegroundColor Gray
Write-Host "  ✅ More professional-looking URL" -ForegroundColor Gray
Write-Host ""

Write-Host "To use port 80:" -ForegroundColor White
Write-Host "  1. Change OnPrem to port 80 (see instructions in fix-traffic-manager-use-port80.ps1)" -ForegroundColor Gray
Write-Host "  2. Run: .\scripts\fix-traffic-manager-use-port80.ps1" -ForegroundColor Gray
Write-Host "  3. Delete the non-working port 31514 service (optional cleanup)" -ForegroundColor Gray
Write-Host ""

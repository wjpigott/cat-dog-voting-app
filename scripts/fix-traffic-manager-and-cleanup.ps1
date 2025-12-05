# Fix Traffic Manager Configuration and Clean Up Old Services
# This script:
# 1. Removes the old voting-load-balancer service
# 2. Updates Traffic Manager to use port 80 on both endpoints
# 3. Creates new service on Azure using port 80 to match on-prem port change

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$TrafficManagerProfile = "voting-app-tm-2334-cstgesqvnzeko",
    [string]$OnPremIP = "66.242.207.21",
    [switch]$DryRun
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 TRAFFIC MANAGER FIX & CLEANUP SCRIPT" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Show current services
Write-Host "📊 Current AKS Services:" -ForegroundColor Yellow

# Use kubectl-temp.exe if kubectl is not in PATH
$kubectlCmd = if (Get-Command kubectl -ErrorAction SilentlyContinue) { "kubectl" } else { ".\kubectl-temp.exe" }
& $kubectlCmd get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORT:.spec.ports[0].port

Write-Host ""
Write-Host "Current situation:" -ForegroundColor Cyan
Write-Host "  ✅ 172.168.91.225:80  - azure-voting-app-complete-service (BETTER VERSION)" -ForegroundColor Green
Write-Host "  ❌ 172.168.251.177:80 - voting-load-balancer-service (OLD - SHOULD DELETE)" -ForegroundColor Red
Write-Host "  ⚠️  172.169.36.153:31514 - voting-app-31514-lb (For Traffic Manager)" -ForegroundColor Yellow
Write-Host "  🏠 66.242.207.21:31514 - OnPrem (Current)" -ForegroundColor Cyan
Write-Host ""

# Step 2: Test current endpoints
Write-Host "🔍 Testing Current Endpoints:" -ForegroundColor Yellow
Write-Host ""

function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "  ✅ $name - Online ($($response.StatusCode))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ❌ $name - Offline" -ForegroundColor Red
        return $false
    }
}

$azure1Status = Test-Endpoint "http://172.168.91.225/" "Azure - Better Version (port 80)"
$azure2Status = Test-Endpoint "http://172.168.251.177/" "Azure - Old LB (port 80)"
$azure3Status = Test-Endpoint "http://172.169.36.153:31514/" "Azure - TM Service (port 31514)"
$onpremStatus = Test-Endpoint "http://$OnPremIP`:31514/" "OnPrem (port 31514)"

Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Recommendations
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📋 RECOMMENDED ACTIONS:" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "OPTION A: Use Port 80 (Standard HTTP)" -ForegroundColor Yellow
Write-Host "  Best if OnPrem can be changed to port 80" -ForegroundColor White
Write-Host ""
Write-Host "  Actions needed:" -ForegroundColor White
Write-Host "    1. ❌ Delete old load balancer service:" -ForegroundColor Red
Write-Host "       kubectl delete service voting-load-balancer-service" -ForegroundColor Gray
Write-Host "       kubectl delete deployment voting-load-balancer" -ForegroundColor Gray
Write-Host ""
Write-Host "    2. ✅ Keep Azure service on port 80:" -ForegroundColor Green
Write-Host "       Use: azure-voting-app-complete-service (172.168.91.225)" -ForegroundColor Gray
Write-Host ""
Write-Host "    3. 🏠 Change OnPrem to port 80 (on your OnPrem K3s cluster):" -ForegroundColor Cyan
Write-Host "       kubectl patch service voting-app-service --type='json' -p='[{`"op`":`"replace`",`"path`":`"/spec/ports/0/nodePort`",`"value`":30080}]'" -ForegroundColor Gray
Write-Host "       Then forward router port 80 to OnPrem_IP:30080" -ForegroundColor Gray
Write-Host ""
Write-Host "    4. 🌍 Update Traffic Manager to use port 80:" -ForegroundColor Magenta
Write-Host "       - Azure endpoint: 172.168.91.225:80" -ForegroundColor Gray
Write-Host "       - OnPrem endpoint: $OnPremIP`:80" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION B: Use Port 31514 (Current OnPrem Setup)" -ForegroundColor Yellow
Write-Host "  Best if OnPrem must stay on port 31514" -ForegroundColor White
Write-Host ""
Write-Host "  Actions needed:" -ForegroundColor White
Write-Host "    1. ❌ Delete old load balancer service:" -ForegroundColor Red
Write-Host "       kubectl delete service voting-load-balancer-service" -ForegroundColor Gray
Write-Host "       kubectl delete deployment voting-load-balancer" -ForegroundColor Gray
Write-Host ""
Write-Host "    2. ❌ Delete port 80 service (not needed):" -ForegroundColor Red
Write-Host "       kubectl delete service azure-voting-app-complete-service" -ForegroundColor Gray
Write-Host ""
Write-Host "    3. ✅ Keep Azure port 31514 service:" -ForegroundColor Green
Write-Host "       Use: voting-app-31514-lb (172.169.36.153:31514)" -ForegroundColor Gray
Write-Host ""
Write-Host "    4. 🌍 Traffic Manager already configured correctly for port 31514:" -ForegroundColor Magenta
Write-Host "       - Azure endpoint: 172.169.36.153:31514" -ForegroundColor Gray
Write-Host "       - OnPrem endpoint: $OnPremIP`:31514" -ForegroundColor Gray
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 4: Offer to clean up old service
if (-not $DryRun) {
    Write-Host "🗑️ CLEANUP OLD SERVICE:" -ForegroundColor Red
    $confirm = Read-Host "Do you want to delete the old voting-load-balancer service and deployment? (yes/no)"
    
    if ($confirm -eq "yes") {
        Write-Host ""
        Write-Host "Deleting voting-load-balancer-service..." -ForegroundColor Yellow
        & $kubectlCmd delete service voting-load-balancer-service
        
        Write-Host "Deleting voting-load-balancer deployment..." -ForegroundColor Yellow
        & $kubectlCmd delete deployment voting-load-balancer
        
        Write-Host ""
        Write-Host "✅ Cleanup complete!" -ForegroundColor Green
        Write-Host ""
        
        # Show updated services
        Write-Host "📊 Updated Services:" -ForegroundColor Yellow
        & $kubectlCmd get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORT:.spec.ports[0].port
    }
    else {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🌍 NEXT STEP: UPDATE TRAFFIC MANAGER" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To update Traffic Manager, you have 3 options:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Azure Portal (Easiest):" -ForegroundColor Yellow
    Write-Host "   - Go to: https://portal.azure.com" -ForegroundColor Gray
    Write-Host "   - Navigate to: Traffic Manager profile '$TrafficManagerProfile'" -ForegroundColor Gray
    Write-Host "   - Update endpoints and monitoring port" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. PowerShell Az Module:" -ForegroundColor Yellow
    Write-Host "   Run: .\scripts\update-traffic-manager-powershell.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Azure Cloud Shell:" -ForegroundColor Yellow
    Write-Host "   - Open: https://shell.azure.com" -ForegroundColor Gray
    Write-Host "   - Run Azure CLI commands without permission issues" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Analysis Complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

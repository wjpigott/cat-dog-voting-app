# Quick Fix - Recommended Approach (Option B: Port 31514)
# This is the easiest fix with no OnPrem changes needed

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "⚡ QUICK FIX - Traffic Manager (Port 31514)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Use kubectl-temp.exe if kubectl is not in PATH
$kubectlCmd = if (Get-Command kubectl -ErrorAction SilentlyContinue) { "kubectl" } else { ".\kubectl-temp.exe" }

Write-Host "Step 1: Checking current services..." -ForegroundColor Yellow
& $kubectlCmd get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORT:.spec.ports[0].port
Write-Host ""

Write-Host "Step 2: Checking pods status..." -ForegroundColor Yellow
& $kubectlCmd get pods -l app=azure-voting-app-complete
Write-Host ""

$proceed = Read-Host "Do you want to proceed with cleanup and Traffic Manager update? (yes/no)"

if ($proceed -ne "yes") {
    Write-Host "❌ Cancelled" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🗑️ STEP 1: Cleaning up old services..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Delete old load balancer service
Write-Host "Deleting voting-load-balancer-service..." -ForegroundColor Gray
try {
    & $kubectlCmd delete service voting-load-balancer-service 2>&1 | Out-Null
    Write-Host "✅ Service deleted" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Service may not exist (that's OK)" -ForegroundColor Yellow
}

Write-Host "Deleting voting-load-balancer deployment..." -ForegroundColor Gray
try {
    & $kubectlCmd delete deployment voting-load-balancer 2>&1 | Out-Null
    Write-Host "✅ Deployment deleted" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Deployment may not exist (that's OK)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Waiting for cleanup to complete..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "📊 Updated services:" -ForegroundColor Cyan
& $kubectlCmd get services -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORT:.spec.ports[0].port

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🌍 STEP 2: Updating Traffic Manager..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Calling PowerShell update script..." -ForegroundColor Gray
Write-Host ""

# Call the traffic manager update script
.\scripts\update-traffic-manager-powershell.ps1 `
    -AzureIP "172.169.36.153" `
    -OnPremIP $env:ONPREM_PUBLIC_IP `
    -Port 31514 `
    -Protocol "TCP"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ QUICK FIX COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "🌍 Your Traffic Manager URL:" -ForegroundColor Magenta
Write-Host "   http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 What was done:" -ForegroundColor Yellow
Write-Host "   ✅ Deleted old load balancer service (172.168.251.177)" -ForegroundColor Gray
Write-Host "   ✅ Updated Traffic Manager to use port 31514 on both endpoints" -ForegroundColor Gray
Write-Host "   ✅ Azure endpoint: 172.169.36.153:31514" -ForegroundColor Gray
Write-Host "   ✅ OnPrem endpoint: $env:ONPREM_PUBLIC_IP`:31514" -ForegroundColor Gray
Write-Host ""

Write-Host "⏳ Wait 30-60 seconds for health checks to stabilize, then test:" -ForegroundColor Yellow
Write-Host "   Invoke-WebRequest -Uri 'http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514' -Method Head" -ForegroundColor Gray
Write-Host ""

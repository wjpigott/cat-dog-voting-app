# 🚀 AZURE TRAFFIC MANAGER - MANUAL DEPLOYMENT GUIDE

Write-Host "🌐 AZURE TRAFFIC MANAGER DEPLOYMENT" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Gray

$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "`n📋 STEP-BY-STEP DEPLOYMENT:" -ForegroundColor Green

Write-Host "`n1️⃣ OPEN AZURE PORTAL" -ForegroundColor Cyan
Write-Host "   Go to: https://portal.azure.com" -ForegroundColor White

Write-Host "`n2️⃣ CREATE TRAFFIC MANAGER PROFILE" -ForegroundColor Cyan
Write-Host "   • Click 'Create a resource'" -ForegroundColor White
Write-Host "   • Search: 'Traffic Manager profile'" -ForegroundColor White
Write-Host "   • Click 'Create'" -ForegroundColor White

Write-Host "`n3️⃣ BASIC CONFIGURATION" -ForegroundColor Cyan
Write-Host "   • Name: $ProfileName" -ForegroundColor Yellow
Write-Host "   • Routing method: Priority" -ForegroundColor Yellow
Write-Host "   • Subscription: (your subscription)" -ForegroundColor Yellow
Write-Host "   • Resource group: rg-cat-dog-voting" -ForegroundColor Yellow
Write-Host "   • Resource group location: Central US" -ForegroundColor Yellow

Write-Host "`n4️⃣ CLICK 'REVIEW + CREATE'" -ForegroundColor Cyan
Write-Host "   • Review settings" -ForegroundColor White
Write-Host "   • Click 'Create'" -ForegroundColor White
Write-Host "   • Wait for deployment to complete" -ForegroundColor White

Write-Host "`n5️⃣ ADD ENDPOINTS" -ForegroundColor Cyan
Write-Host "   After deployment completes:" -ForegroundColor Gray
Write-Host "   • Go to your new Traffic Manager profile" -ForegroundColor White
Write-Host "   • Click 'Endpoints' in the left menu" -ForegroundColor White
Write-Host "   • Click '+ Add'" -ForegroundColor White

Write-Host "`n   📍 ENDPOINT 1 (Primary - Azure AKS):" -ForegroundColor Green
Write-Host "   • Type: External endpoint" -ForegroundColor White
Write-Host "   • Name: azure-aks-primary" -ForegroundColor Yellow
Write-Host "   • Target: 52.154.54.110" -ForegroundColor Yellow
Write-Host "   • Priority: 1" -ForegroundColor Yellow
Write-Host "   • Click 'Add'" -ForegroundColor White

Write-Host "`n   📍 ENDPOINT 2 (Backup - OnPrem):" -ForegroundColor Blue
Write-Host "   • Click '+ Add' again" -ForegroundColor White
Write-Host "   • Type: External endpoint" -ForegroundColor White
Write-Host "   • Name: onprem-backup" -ForegroundColor Yellow
Write-Host "   • Target: 66.242.207.21" -ForegroundColor Yellow
Write-Host "   • Priority: 2" -ForegroundColor Yellow
Write-Host "   • Click 'Add'" -ForegroundColor White

Write-Host "`n6️⃣ CONFIGURE MONITORING" -ForegroundColor Cyan
Write-Host "   • Click 'Configuration' in the left menu" -ForegroundColor White
Write-Host "   • Protocol: HTTP" -ForegroundColor Yellow
Write-Host "   • Port: 80" -ForegroundColor Yellow
Write-Host "   • Path: /" -ForegroundColor Yellow
Write-Host "   • Probing interval: 30 seconds" -ForegroundColor Yellow
Write-Host "   • Tolerated failures: 3" -ForegroundColor Yellow
Write-Host "   • Click 'Save'" -ForegroundColor White

Write-Host "`n✅ YOUR TRAFFIC MANAGER URL:" -ForegroundColor Green
Write-Host "http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta

Write-Host "`n🧪 TEST FAILOVER:" -ForegroundColor Yellow
Write-Host "After deployment, test with:" -ForegroundColor Gray
Write-Host ".\scripts\test-failover-tm.sh `"http://$ProfileName.trafficmanager.net`"" -ForegroundColor DarkGray

Write-Host "`n⏱️ EXPECTED TIMELINE:" -ForegroundColor Cyan
Write-Host "• Profile creation: 2-3 minutes" -ForegroundColor Gray
Write-Host "• Endpoint configuration: 2-3 minutes" -ForegroundColor Gray  
Write-Host "• DNS propagation: 5-10 minutes" -ForegroundColor Gray
Write-Host "• Total time: ~15 minutes" -ForegroundColor Yellow

Write-Host "`n🎯 FAILOVER BEHAVIOR:" -ForegroundColor Magenta
Write-Host "• Normal: Routes to Azure AKS (Priority 1)" -ForegroundColor Green
Write-Host "• Azure down: Auto-routes to OnPrem (Priority 2)" -ForegroundColor Yellow
Write-Host "• Azure back up: Auto-routes back to Azure" -ForegroundColor Green

# Try opening the portal directly
Write-Host "`n🌐 Opening Azure Portal..." -ForegroundColor Blue
try {
    Start-Process "https://portal.azure.com/#create/Microsoft.Template"
    Write-Host "✅ Portal opened! Follow the steps above." -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Could not auto-open portal. Please visit: https://portal.azure.com" -ForegroundColor Yellow
}
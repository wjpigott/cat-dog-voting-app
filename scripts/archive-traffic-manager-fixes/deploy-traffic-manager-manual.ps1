# Azure Traffic Manager Deployment Guide
# Since Azure CLI has permission issues, we'll use the Azure portal

Write-Host "🚀 AZURE TRAFFIC MANAGER DEPLOYMENT GUIDE" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "`n⚠️  Azure CLI Permission Issue Detected" -ForegroundColor Yellow
Write-Host "We'll deploy using the Azure Portal instead.`n" -ForegroundColor Gray

Write-Host "📋 MANUAL DEPLOYMENT STEPS:" -ForegroundColor Cyan
Write-Host "1. Open Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Click 'Create a resource'" -ForegroundColor White
Write-Host "3. Search for 'Traffic Manager profile'" -ForegroundColor White
Write-Host "4. Click 'Create'" -ForegroundColor White

Write-Host "`n⚙️  CONFIGURATION VALUES:" -ForegroundColor Magenta
$profileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Host "Name: $profileName" -ForegroundColor Yellow
Write-Host "DNS name: $profileName" -ForegroundColor Yellow
Write-Host "Routing method: Priority" -ForegroundColor Yellow
Write-Host "Resource group: rg-cat-dog-voting" -ForegroundColor Yellow
Write-Host "Location: Global" -ForegroundColor Yellow

Write-Host "`n🎯 ENDPOINT CONFIGURATION:" -ForegroundColor Magenta
Write-Host "After creating the profile, add these endpoints:" -ForegroundColor Gray

Write-Host "`n📍 Endpoint 1 (Primary - Azure AKS):" -ForegroundColor Green
Write-Host "Name: azure-aks-primary" -ForegroundColor White
Write-Host "Type: External endpoint" -ForegroundColor White
Write-Host "Target: 52.154.54.110" -ForegroundColor Yellow
Write-Host "Priority: 1" -ForegroundColor Yellow

Write-Host "`n📍 Endpoint 2 (Backup - OnPrem):" -ForegroundColor Cyan
Write-Host "Name: onprem-backup" -ForegroundColor White
Write-Host "Type: External endpoint" -ForegroundColor White
Write-Host "Target: 66.242.207.21" -ForegroundColor Yellow
Write-Host "Priority: 2" -ForegroundColor Yellow

Write-Host "`n❤️  HEALTH MONITORING:" -ForegroundColor Red
Write-Host "Protocol: HTTP" -ForegroundColor White
Write-Host "Port: 80" -ForegroundColor White
Write-Host "Path: /" -ForegroundColor White
Write-Host "Probing interval: 30 seconds" -ForegroundColor White
Write-Host "Tolerated failures: 3" -ForegroundColor White

Write-Host "`n🌐 YOUR FINAL URL WILL BE:" -ForegroundColor Magenta
Write-Host "http://$profileName.trafficmanager.net" -ForegroundColor Yellow

Write-Host "`n✅ TESTING PLAN:" -ForegroundColor Green
Write-Host "1. Access the Traffic Manager URL" -ForegroundColor White
Write-Host "2. With AKS up: Should route to Azure (52.154.54.110)" -ForegroundColor White
Write-Host "3. Shut down AKS: Should auto-failover to OnPrem (66.242.207.21:31514)" -ForegroundColor White
Write-Host "4. Start AKS: Should fail back to Azure automatically" -ForegroundColor White

Write-Host "`n🚀 ALTERNATIVE: Try Azure CLI as Administrator" -ForegroundColor Cyan
Write-Host "Run PowerShell as Administrator and try:" -ForegroundColor Gray
Write-Host "az group deployment create --resource-group rg-cat-dog-voting --template-file azure-traffic-manager.json" -ForegroundColor DarkGray
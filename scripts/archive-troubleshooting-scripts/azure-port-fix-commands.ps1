# Quick Commands to Complete Port Standardization
# Run these once AKS cluster is started and accessible

Write-Host "⚡ QUICK COMMANDS - AZURE PORT STANDARDIZATION" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n🔧 Step 1: Test AKS connectivity" -ForegroundColor Cyan
Write-Host ".\kubectl.exe config use-context aks-cat-dog-voting" -ForegroundColor Yellow
Write-Host ".\kubectl.exe get nodes" -ForegroundColor Yellow

Write-Host "`n🔧 Step 2: Check current Azure service" -ForegroundColor Cyan  
Write-Host ".\kubectl.exe get services" -ForegroundColor Yellow

Write-Host "`n🔧 Step 3: Change Azure to NodePort 31514 (match OnPrem)" -ForegroundColor Cyan
Write-Host ".\kubectl.exe patch service azure-vote-front --type='json' -p='[{`"op`": `"replace`", `"path`": `"/spec/type`", `"value`": `"NodePort`"},{`"op`": `"replace`", `"path`": `"/spec/ports/0/nodePort`", `"value`": 31514}]'" -ForegroundColor Yellow

Write-Host "`n🔧 Step 4: Get Azure node external IP" -ForegroundColor Cyan
Write-Host ".\kubectl.exe get nodes -o wide" -ForegroundColor Yellow

Write-Host "`n🔧 Step 5: Test Azure endpoint directly" -ForegroundColor Cyan
Write-Host "curl http://AZURE_NODE_IP:31514" -ForegroundColor Yellow

Write-Host "`n🔧 Step 6: Test Traffic Manager (should work now!)" -ForegroundColor Cyan
Write-Host "curl http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514" -ForegroundColor Yellow

Write-Host "`n✅ Expected Result:" -ForegroundColor Green
Write-Host "   Both Azure and OnPrem accessible on port 31514" -ForegroundColor White
Write-Host "   Traffic Manager routes to healthy endpoint automatically" -ForegroundColor White
Write-Host "   Router admin interface stays on port 80 (unchanged)" -ForegroundColor White

Write-Host "`n🧪 Final Verification:" -ForegroundColor Green
Write-Host ".\scripts\test-failover-analysis.ps1" -ForegroundColor Yellow
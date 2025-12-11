# Fix Traffic Manager Port Consistency
# Make both Azure and OnPrem use the same port (31514) for Traffic Manager

Write-Host "🔧 STANDARDIZING PORTS FOR TRAFFIC MANAGER" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "📊 Current Situation:" -ForegroundColor Yellow
Write-Host "   Azure AKS: LoadBalancer on port 80" -ForegroundColor Gray
Write-Host "   OnPrem K3s: NodePort on port 31514" -ForegroundColor Gray
Write-Host "   Traffic Manager: Expects same port on both endpoints" -ForegroundColor Gray

Write-Host "`n🎯 Solution: Make Azure use NodePort 31514 (same as OnPrem)" -ForegroundColor Green

Write-Host "`n🔄 Step 1: Start Azure AKS cluster..." -ForegroundColor Blue
Write-Host "   Run manually: az aks start --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting" -ForegroundColor Gray

Write-Host "`n🔄 Step 2: Update Azure service to NodePort 31514..." -ForegroundColor Blue
Write-Host @"
   # Connect to AKS:
   kubectl config use-context aks-cat-dog-voting
   
   # Check current service:
   kubectl get services
   
   # Update to NodePort 31514 (to match OnPrem):
   kubectl patch service azure-vote-front --type='json' -p='[
     {"op": "replace", "path": "/spec/type", "value": "NodePort"},
     {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31514}
   ]'
   
   # Get the new external IP:
   kubectl get nodes -o wide
"@ -ForegroundColor Gray

Write-Host "`n🔄 Step 3: Update Traffic Manager endpoints..." -ForegroundColor Blue
Write-Host @"
   # Both endpoints will now use the same port:
   Azure: <node-ip>:31514
   OnPrem: 66.242.207.21:31514
   
   # Traffic Manager monitoring:
   Protocol: TCP
   Port: 31514
   
   # Both endpoints accessible on same port!
"@ -ForegroundColor Gray

Write-Host "`n✅ Expected Result:" -ForegroundColor Green
Write-Host "   Traffic Manager URL: http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor Yellow
Write-Host "   Resolves to healthy endpoint automatically" -ForegroundColor Gray
Write-Host "   No port conflicts or router changes needed!" -ForegroundColor Gray

Write-Host "`n📋 Benefits of This Approach:" -ForegroundColor Cyan
Write-Host "   ✅ No router configuration needed" -ForegroundColor Green
Write-Host "   ✅ Both environments use identical ports" -ForegroundColor Green
Write-Host "   ✅ Traffic Manager works perfectly" -ForegroundColor Green
Write-Host "   ✅ Simple and maintainable" -ForegroundColor Green

Write-Host "`n🎯 Next Steps:" -ForegroundColor Magenta
Write-Host "   1. Start AKS cluster (portal or Azure CLI)" -ForegroundColor White
Write-Host "   2. Update Azure service to NodePort 31514" -ForegroundColor White
Write-Host "   3. Test Traffic Manager URL" -ForegroundColor White
Write-Host "   4. Enjoy consistent failover! 🎉" -ForegroundColor White
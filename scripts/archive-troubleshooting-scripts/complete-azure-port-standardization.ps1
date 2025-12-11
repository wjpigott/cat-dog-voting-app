# Complete Azure Port Standardization
# This finishes making both environments use port 31514

param(
    [Parameter(Mandatory=$false)]
    [string]$AksResourceGroup = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$AksClusterName = "aks-cat-dog-voting"
)

Write-Host "🔧 COMPLETING AZURE PORT STANDARDIZATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Write-Host "📊 Current Status:" -ForegroundColor Yellow
Write-Host "   OnPrem: ✅ Using port 31514 (NodePort)" -ForegroundColor Green
Write-Host "   Azure: ⏳ Still using port 80 (LoadBalancer)" -ForegroundColor Yellow
Write-Host "   Traffic Manager: ✅ Monitoring TCP port 31514" -ForegroundColor Green

Write-Host "`n🎯 Goal: Make Azure use NodePort 31514 (same as OnPrem)" -ForegroundColor Green

Write-Host "`n🔄 Step 1: Start Azure AKS cluster..." -ForegroundColor Blue
Write-Host "   Manual step: Go to Azure Portal → AKS → Start cluster" -ForegroundColor Gray
Write-Host "   Or try: az aks start --resource-group $AksResourceGroup --name $AksClusterName" -ForegroundColor Gray

Write-Host "`n🔄 Step 2: Check if AKS is accessible..." -ForegroundColor Blue
try {
    $contextResult = .\kubectl.exe config use-context aks-cat-dog-voting 2>&1
    $nodesResult = .\kubectl.exe get nodes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ AKS cluster is accessible!" -ForegroundColor Green
        Write-Host "`n🔄 Step 3: Get current Azure services..." -ForegroundColor Blue
        .\kubectl.exe get services
        
        Write-Host "`n🔄 Step 4: Update Azure service to NodePort 31514..." -ForegroundColor Blue
        Write-Host "   Executing: kubectl patch service azure-vote-front..." -ForegroundColor Yellow
        
        # Try to patch the service
        $patchResult = .\kubectl.exe patch service azure-vote-front --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"},{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31514}]' 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Azure service updated to NodePort 31514!" -ForegroundColor Green
            
            Write-Host "`n🔄 Step 5: Get Azure node IP..." -ForegroundColor Blue
            $nodeIP = .\kubectl.exe get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>$null
            if (!$nodeIP) {
                $nodeIP = .\kubectl.exe get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>$null
            }
            
            if ($nodeIP) {
                Write-Host "   ✅ Azure node IP: $nodeIP" -ForegroundColor Green
                Write-Host "`n🧪 Test Azure endpoint: http://${nodeIP}:31514" -ForegroundColor Cyan
            }
            
            Write-Host "`n🎯 STANDARDIZATION COMPLETE!" -ForegroundColor Green
            Write-Host "   Both environments now use port 31514" -ForegroundColor Gray
            Write-Host "   Traffic Manager should work perfectly!" -ForegroundColor Gray
            
        } else {
            Write-Host "   ❌ Failed to update service: $patchResult" -ForegroundColor Red
        }
        
    } else {
        Write-Host "   ❌ AKS cluster not accessible: $nodesResult" -ForegroundColor Red
        Write-Host "   Please start the AKS cluster first" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Error connecting to AKS: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Manual Steps if Script Fails:" -ForegroundColor Cyan
Write-Host "   1. Start AKS: az aks start --resource-group $AksResourceGroup --name $AksClusterName" -ForegroundColor White
Write-Host "   2. Connect: kubectl config use-context aks-cat-dog-voting" -ForegroundColor White
Write-Host "   3. Check service: kubectl get services" -ForegroundColor White
Write-Host "   4. Update service: kubectl patch service azure-vote-front --type='json' \\" -ForegroundColor White
Write-Host "      -p='[{\"op\": \"replace\", \"path\": \"/spec/type\", \"value\": \"NodePort\"}," -ForegroundColor White
Write-Host "           {\"op\": \"replace\", \"path\": \"/spec/ports/0/nodePort\", \"value\": 31514}]'" -ForegroundColor White
Write-Host "   5. Get node IP: kubectl get nodes -o wide" -ForegroundColor White
Write-Host "   6. Test: curl http://NODE_IP:31514" -ForegroundColor White

Write-Host "`n🧪 Final Test:" -ForegroundColor Green
Write-Host "   Traffic Manager URL should work: http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net:31514" -ForegroundColor Cyan
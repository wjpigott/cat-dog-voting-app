# Deploy NGINX Proxy to Bridge Port 80 → 31514
# This allows Traffic Manager URL to work without router changes

Write-Host "🚀 DEPLOYING PORT 80 PROXY TO ONPREM K3S" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "📋 This proxy will:" -ForegroundColor Yellow
Write-Host "   Listen on port 80 (what browsers expect)" -ForegroundColor Gray
Write-Host "   Forward to port 31514 (where your app runs)" -ForegroundColor Gray
Write-Host "   Make Traffic Manager URL work perfectly!" -ForegroundColor Green

Write-Host "`n🔧 Instructions:" -ForegroundColor Cyan
Write-Host "1. SSH to your K3s machine (66.242.207.21)" -ForegroundColor White
Write-Host "2. Copy the proxy YAML file to your K3s machine" -ForegroundColor White
Write-Host "3. Deploy with: k3s kubectl apply -f onprem-proxy-port80.yaml" -ForegroundColor White
Write-Host "4. Test: curl http://66.242.207.21 (should show your voting app!)" -ForegroundColor White

Write-Host "`n📁 Proxy file created: onprem-proxy-port80.yaml" -ForegroundColor Green
Write-Host "   This NGINX proxy listens on NodePort 30080" -ForegroundColor Gray
Write-Host "   Router should forward port 80 → port 30080" -ForegroundColor Gray

Write-Host "`n⚡ Alternative Quick Command:" -ForegroundColor Cyan
Write-Host "k3s kubectl run nginx-proxy --image=nginx --port=80 --expose --type=NodePort" -ForegroundColor Yellow

Write-Host "`n🧪 After deployment, test:" -ForegroundColor Green
Write-Host "   http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net" -ForegroundColor Cyan
Write-Host "   Should show your voting app instead of router login!" -ForegroundColor Gray
# Fix for Traffic Manager - Change On-Premises to Port 80
# This makes both environments use the same port (80) for Traffic Manager compatibility

Write-Host "🔧 Modifying On-Premises Service for Traffic Manager Compatibility" -ForegroundColor Green
Write-Host "Changing from NodePort 31514 to port 80 using LoadBalancer or Ingress" -ForegroundColor Cyan

# Option A: Change to LoadBalancer (if supported by your on-premises setup)
$loadBalancerConfig = @"
apiVersion: v1
kind: Service
metadata:
  name: voting-app-service-onprem-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: voting-app-onprem
"@

# Option B: Use NodePort with port 80 (requires root/admin)
$nodePortConfig = @"
apiVersion: v1
kind: Service
metadata:
  name: voting-app-service-onprem-port80
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: voting-app-onprem
"@

Write-Host "Choose your configuration option:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option A: LoadBalancer (Recommended if supported)" -ForegroundColor Green
Write-Host "kubectl apply -f -" -ForegroundColor White
Write-Host $loadBalancerConfig -ForegroundColor Gray
Write-Host ""
Write-Host "Option B: NodePort on port 30080" -ForegroundColor Blue
Write-Host "kubectl apply -f -" -ForegroundColor White  
Write-Host $nodePortConfig -ForegroundColor Gray
Write-Host ""

# Save both options to files
$loadBalancerConfig | Set-Content -Path "onprem-loadbalancer-port80.yaml"
$nodePortConfig | Set-Content -Path "onprem-nodeport-port80.yaml"

Write-Host "Files saved:" -ForegroundColor Green
Write-Host "  onprem-loadbalancer-port80.yaml" -ForegroundColor White
Write-Host "  onprem-nodeport-port80.yaml" -ForegroundColor White
Write-Host ""
Write-Host "After applying, update Traffic Manager with:" -ForegroundColor Cyan
Write-Host "  Azure endpoint: 52.154.54.110:80" -ForegroundColor White
Write-Host "  On-prem endpoint: 66.242.207.21:80 (LoadBalancer)" -ForegroundColor White
Write-Host "  OR: 66.242.207.21:30080 (NodePort)" -ForegroundColor White
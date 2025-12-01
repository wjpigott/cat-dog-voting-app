# Deployment Best Practices for Traffic Manager

## Port Consistency Guidelines

### Rule #1: Plan Ports Before Deployment

**Traffic Manager requires all endpoints to use the same external port.**

### Recommended Port Strategies

#### Strategy A: Standard HTTP Port 80 (Recommended)

**OnPrem K3s Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: voting-app
spec:
  type: NodePort
  ports:
  - port: 80          # Internal service port
    targetPort: 8080  # Application container port
    nodePort: 30080   # External port (avoid 31514 conflicts)
  selector:
    app: voting-app
```

**Azure AKS Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: voting-app
spec:
  type: LoadBalancer
  ports:
  - port: 80          # External load balancer port
    targetPort: 8080  # Application container port
  selector:
    app: voting-app
```

**Traffic Manager Configuration:**
```json
{
  "monitorProtocol": "HTTP",
  "monitorPort": 80,
  "monitorPath": "/health",
  "endpoints": [
    {"target": "azure-lb-ip", "priority": 1},
    {"target": "onprem-public-ip", "priority": 2}
  ]
}
```

**Benefits:**
- ✅ Standard HTTP port
- ✅ No router conflicts (if router uses different port)
- ✅ HTTP health monitoring available
- ✅ Corporate firewall friendly

#### Strategy B: Consistent Custom Port (Alternative)

**Both OnPrem and Azure use NodePort 31514:**

**OnPrem K3s:** (Keep existing)
```yaml
spec:
  type: NodePort
  ports:
  - nodePort: 31514
```

**Azure AKS:** (Change to match)
```bash
kubectl patch service voting-app --type='json' -p='[
  {"op": "replace", "path": "/spec/type", "value": "NodePort"},
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31514}
]'
```

**Traffic Manager Configuration:**
```json
{
  "monitorProtocol": "TCP",
  "monitorPort": 31514,
  "endpoints": [
    {"target": "azure-node-ip", "priority": 1},
    {"target": "onprem-public-ip", "priority": 2}
  ]
}
```

**Benefits:**
- ✅ No router management conflicts
- ✅ Consistent with existing OnPrem setup
- ✅ Simple TCP health monitoring

## Deployment Checklist

### Pre-Deployment Planning

- [ ] **Port Strategy Decided**: Will both environments use port 80 or 31514?
- [ ] **Router Conflicts Checked**: Is chosen port available on router?
- [ ] **Firewall Rules**: Are required ports open?
- [ ] **Health Check Strategy**: HTTP with `/health` or TCP connection?

### OnPrem K3s Deployment

```bash
# Deploy application
kubectl apply -f voting-app-deployment.yaml

# Create service with planned port
kubectl expose deployment voting-app \
  --type=NodePort \
  --port=80 \
  --target-port=8080 \
  --name=voting-service

# Verify external access
curl http://YOUR_ONPREM_IP:$(kubectl get svc voting-service -o jsonpath='{.spec.ports[0].nodePort}')
```

### Azure AKS Deployment

```bash
# Deploy application
kubectl apply -f voting-app-deployment.yaml

# Create service matching OnPrem strategy
# Option 1: LoadBalancer on port 80
kubectl expose deployment voting-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 \
  --name=voting-service

# Option 2: NodePort matching OnPrem
kubectl expose deployment voting-app \
  --type=NodePort \
  --port=80 \
  --target-port=8080 \
  --node-port=31514 \
  --name=voting-service

# Verify external access
curl http://$(kubectl get svc voting-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):80
```

### Traffic Manager Configuration

```powershell
# Deploy with consistent port configuration
.\scripts\deploy-traffic-manager.ps1 -MonitorPort 80

# Verify both endpoints respond on same port
.\scripts\test-failover-analysis.ps1
```

### Post-Deployment Validation

- [ ] **Both endpoints accessible** on the same port
- [ ] **Traffic Manager resolves** to healthy endpoint
- [ ] **Health checks passing** in Traffic Manager portal
- [ ] **Failover testing** successful
- [ ] **Application functionality** verified through Traffic Manager URL

## Common Issues and Solutions

### Issue: Port Mismatch After Deployment

**Symptoms:** Traffic Manager URL shows router login or 404 error

**Solution:** 
```bash
# Quick fix: Standardize on existing OnPrem port
kubectl patch service voting-service --type='json' -p='[
  {"op": "replace", "path": "/spec/type", "value": "NodePort"},
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31514}
]'
```

### Issue: Router Management Conflicts

**Symptoms:** Can't access router admin when using port 80

**Solution:**
```bash
# Use different port (e.g., 8080) for applications
# Update both environments to use consistent alternative port
```

### Issue: Corporate Firewall Blocking

**Symptoms:** External access fails on custom ports

**Solution:**
```bash
# Use standard ports (80, 443, 8080) that are typically allowed
# Work with IT team to open required ports
```

## Port Reference Guide

| Port | Use Case | Pros | Cons |
|------|----------|------|------|
| 80 | Standard HTTP | Firewall friendly, familiar | May conflict with router |
| 8080 | Alternative HTTP | Common alternative, allowed by most firewalls | Non-standard |
| 31514 | K8s NodePort | High port, unlikely conflicts | May be blocked by firewalls |
| 30080 | K8s NodePort | Standard NodePort range | May be blocked by firewalls |

## Troubleshooting Commands

```powershell
# Check service configuration
kubectl get services -o wide

# Test endpoint directly
curl -I http://ENDPOINT_IP:PORT

# Check Traffic Manager health
Get-AzTrafficManagerProfile | Select-Object MonitorProtocol, MonitorPort

# Test DNS resolution
nslookup TRAFFIC_MANAGER_URL

# Full failover test
.\scripts\test-failover-analysis.ps1
```

Remember: **Consistency is key!** Whatever port strategy you choose, ensure both environments match exactly.
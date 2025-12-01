# Traffic Manager Port Consistency Troubleshooting

## Problem: Traffic Manager Port Mismatch

**Symptoms:**
- Traffic Manager DNS resolves correctly (e.g., to `66.242.207.21`)
- Direct endpoint access works (e.g., `http://66.242.207.21:31514`)
- Traffic Manager URL fails (e.g., `http://voting-app-tm-xxx.trafficmanager.net`)
- Router login page appears instead of your application

**Root Cause:**
Azure Traffic Manager requires all endpoints to use the same port. If your environments use different ports:
- Azure AKS: LoadBalancer on port 80
- OnPrem K3s: NodePort on port 31514

Traffic Manager tries to access both on the configured port (e.g., 80), but OnPrem isn't listening on that port.

## Solution Options

### Option 1: Standardize on Port 31514 (Recommended)

**Make Azure match OnPrem's NodePort:**

```bash
# 1. Start Azure AKS cluster
az aks start --resource-group <your-rg> --name <your-aks>

# 2. Connect to AKS
kubectl config use-context <aks-context>

# 3. Change Azure service from LoadBalancer:80 to NodePort:31514
kubectl patch service <service-name> --type='json' -p='[
  {"op": "replace", "path": "/spec/type", "value": "NodePort"},
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31514}
]'

# 4. Get Azure node IP
kubectl get nodes -o wide

# 5. Update Traffic Manager endpoint to use node IP
```

### Option 2: Standardize on Port 80

**Make OnPrem match Azure's port 80:**

```bash
# SSH to your K3s machine and run:

# Option A: Change existing service to port 80
kubectl patch service <service-name> --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}
]'

# Option B: Add router port forwarding (if you control the router)
# Forward port 80 → internal K3s port 31514

# Option C: Deploy NGINX proxy on port 80 (see ONPREM_HEALTH_PROXY_INSTRUCTIONS.md)
```

### Option 3: Use NGINX Proxy on Both Environments

**Deploy consistent proxy layer:**

```bash
# Deploy proxy on both Azure and OnPrem
# Both listen on port 80, forward to application port
# See: onprem-proxy-port80.yaml
```

## Prevention for New Deployments

### Recommended Service Configuration

**For K3s (OnPrem):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: voting-app
spec:
  type: NodePort
  ports:
  - port: 80          # Internal cluster port
    targetPort: 8080  # Application container port
    nodePort: 30080   # External access port
  selector:
    app: voting-app
```

**For AKS (Azure):**
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

**Result:** Both accessible on port 80 externally.

### Traffic Manager Configuration

**With consistent ports:**
```json
{
  "monitorProtocol": "HTTP",
  "monitorPort": 80,
  "monitorPath": "/",
  "endpoints": [
    {
      "name": "azure-primary",
      "target": "azure-lb-ip",
      "priority": 1
    },
    {
      "name": "onprem-backup", 
      "target": "onprem-external-ip",
      "priority": 2
    }
  ]
}
```

## Testing

### Verify Port Consistency

```powershell
# Test Azure endpoint
curl http://<azure-ip>:80

# Test OnPrem endpoint  
curl http://<onprem-ip>:80

# Test Traffic Manager
curl http://voting-app-tm-xxx.trafficmanager.net

# All should return the same application!
```

### Traffic Manager Health Check

```powershell
# Check endpoint health
Get-AzTrafficManagerProfile -Name <profile> -ResourceGroupName <rg> | 
  Select-Object -ExpandProperty Endpoints | 
  Select-Object Name, Target, EndpointMonitorStatus

# Both should show "Online"
```

## Common Pitfalls

❌ **Different service types**: LoadBalancer vs NodePort  
❌ **Different external ports**: 80 vs 31514  
❌ **Router conflicts**: Using port 80 when router management uses it  
❌ **Firewall blocking**: Non-standard ports blocked by corporate firewall  

✅ **Best practices**:  
- Plan port strategy before deployment
- Use standard ports (80, 443) when possible
- Document port assignments
- Test both endpoints independently before configuring Traffic Manager

## Quick Reference Commands

```powershell
# Check current service configuration
kubectl get services -o wide

# Change service type and port
kubectl patch service <name> --type='json' -p='[
  {"op": "replace", "path": "/spec/type", "value": "NodePort"},
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}
]'

# Test Traffic Manager resolution
nslookup voting-app-tm-xxx.trafficmanager.net

# Test endpoint directly
curl -I http://<ip>:<port>

# Check Traffic Manager health
.\scripts\test-failover-analysis.ps1
```
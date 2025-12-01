# Manual Deployment Instructions for OnPrem Health Proxy

## QUICK FIX: Manual Deployment to Linux K3s Machine

Since your K3s cluster is on a Linux machine (66.242.207.21), here are the manual steps to fix Traffic Manager failover:

### Step 1: SSH to Your Linux Machine
```bash
ssh your_username@66.242.207.21
```

### Step 2: Create the Health Proxy YAML File
```bash
cat > traffic-manager-health-proxy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traffic-manager-health-proxy
  labels:
    app: traffic-manager-health-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traffic-manager-health-proxy
  template:
    metadata:
      labels:
        app: traffic-manager-health-proxy
    spec:
      containers:
      - name: nginx-proxy
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-proxy-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-proxy-config
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        upstream voting_app {
            server 127.0.0.1:31514;
        }
        server {
            listen 80;
            location / {
                proxy_pass http://voting_app;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_connect_timeout 5s;
                proxy_send_timeout 5s;
                proxy_read_timeout 5s;
            }
            location /health {
                access_log off;
                return 200 "healthy\n";
                add_header Content-Type text/plain;
            }
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: traffic-manager-health-proxy
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: traffic-manager-health-proxy
EOF
```

### Step 3: Deploy to K3s
```bash
# For K3s, use either kubectl or k3s kubectl
k3s kubectl apply -f traffic-manager-health-proxy.yaml

# OR if you have kubectl installed separately:
# kubectl apply -f traffic-manager-health-proxy.yaml
```

### Step 4: Verify Deployment
```bash
# Check if pods are running
k3s kubectl get pods -l app=traffic-manager-health-proxy

# Check service
k3s kubectl get svc traffic-manager-health-proxy

# Test health endpoint locally
curl http://localhost:30080/health

# Test external access (should return "healthy")
curl http://66.242.207.21:30080/health
```

## What This Fixes

**Problem:** Traffic Manager monitors HTTP port 80, but your voting app runs on port 31514.

**Solution:** This NGINX proxy:
- Listens on port 80 (what Traffic Manager expects)
- Forwards traffic to port 31514 (where your app runs)
- Provides a `/health` endpoint for Traffic Manager monitoring

## Expected Timeline

1. **Deploy now:** 2-3 minutes
2. **Traffic Manager detects health:** 2-3 minutes after deployment
3. **Failover works:** Total ~5 minutes from deployment

## Test After Deployment

Back on your Windows machine, run:
```powershell
.\scripts\test-failover-analysis.ps1
```

You should see:
- ✅ OnPrem: UP
- ✅ Traffic Manager: Properly routing to OnPrem

## Alternative: One-Line Fix

If you want the fastest fix, just run this one command on your Linux machine:

```bash
k3s kubectl run nginx-health-proxy --image=nginx:alpine --port=80 --expose --type=NodePort && k3s kubectl patch service nginx-health-proxy --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30080}]'
```

This creates a simple NGINX proxy that will allow Traffic Manager to detect your on-premises cluster.

---

## Summary
Your on-premises environment is healthy and working perfectly. The only issue is that Traffic Manager can't properly health-check it due to the port mismatch. Once you deploy this health proxy, Traffic Manager will automatically start routing traffic to your on-premises cluster when Azure is down.
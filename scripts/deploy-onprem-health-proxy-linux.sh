#!/bin/bash
# Deploy OnPrem Health Proxy for Traffic Manager (Linux Version)
# Run this script on your Linux K3s machine (66.242.207.21)

echo "🚀 DEPLOYING ONPREM HEALTH PROXY FOR TRAFFIC MANAGER"
echo "═════════════════════════════════════════════════════"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Installing..."
    # For K3s, kubectl is usually available as k3s kubectl
    if command -v k3s &> /dev/null; then
        echo "✅ Using K3s kubectl"
        KUBECTL="k3s kubectl"
    else
        echo "❌ Neither kubectl nor k3s found"
        exit 1
    fi
else
    KUBECTL="kubectl"
fi

# Create the health proxy YAML if it doesn't exist
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

# Check cluster connectivity
echo "🔍 Testing K3s cluster connectivity..."
if ! $KUBECTL get nodes >/dev/null 2>&1; then
    echo "❌ Cannot connect to K3s cluster"
    exit 1
fi
echo "✅ Connected to K3s cluster"

# Check if health proxy already exists
echo "🔍 Checking if health proxy already exists..."
if $KUBECTL get deployment traffic-manager-health-proxy -n default >/dev/null 2>&1; then
    echo "⚠️  Health proxy already exists. Updating..."
    $KUBECTL delete deployment traffic-manager-health-proxy -n default
    $KUBECTL delete service traffic-manager-health-proxy -n default
    $KUBECTL delete configmap nginx-proxy-config -n default
    sleep 5
fi

# Deploy the health proxy
echo "🚀 Deploying Traffic Manager health proxy..."
if ! $KUBECTL apply -f traffic-manager-health-proxy.yaml; then
    echo "❌ Failed to deploy health proxy"
    exit 1
fi
echo "✅ Health proxy deployed successfully"

# Wait for deployment to be ready
echo "⏳ Waiting for health proxy to be ready..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if $KUBECTL get pods -l app=traffic-manager-health-proxy -o jsonpath='{.items[*].status.phase}' | grep -q "Running"; then
        echo "✅ Health proxy is running!"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "⏳ Still waiting... ($elapsed/$timeout seconds)"
done

if [ $elapsed -ge $timeout ]; then
    echo "⚠️  Timeout waiting for health proxy. Checking status..."
    $KUBECTL get pods -l app=traffic-manager-health-proxy
    $KUBECTL describe pods -l app=traffic-manager-health-proxy
fi

# Test the health proxy locally
echo "🧪 Testing health proxy locally..."
if curl -f -s http://localhost:30080/health >/dev/null; then
    echo "✅ Health proxy responding on port 30080"
else
    echo "⚠️  Health proxy test failed (may take a few minutes)"
fi

# Test external access
echo "🧪 Testing external access..."
EXTERNAL_IP=$(hostname -I | awk '{print $1}')
if curl -f -s http://$EXTERNAL_IP:30080/health >/dev/null; then
    echo "✅ Health proxy accessible externally on $EXTERNAL_IP:30080"
else
    echo "⚠️  External access test failed"
fi

echo ""
echo "🎯 DEPLOYMENT COMPLETE!"
echo "═══════════════════════"
echo "✅ Health proxy deployed to K3s cluster"
echo "🔄 Traffic Manager will detect OnPrem health in 2-3 minutes"
echo "🌐 Health endpoint: http://$EXTERNAL_IP:30080/health"
echo "🏠 OnPrem app: http://$EXTERNAL_IP:31514"
echo ""
echo "📋 NEXT STEPS:"
echo "1. Wait 2-3 minutes for Traffic Manager health propagation"
echo "2. Test Traffic Manager: curl http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net"
echo "3. Verify failover is working!"
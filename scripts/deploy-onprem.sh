#!/bin/bash

echo "🏠 Deploying Cat/Dog Voting App to On-Premises Azure Arc Kubernetes"
echo "=================================================================="

# Check if kubectl is connected to the right cluster
echo "📋 Checking current Kubernetes context..."
kubectl config current-context

echo ""
echo "🧹 Cleaning up any existing deployments..."

# Clean up any existing voting app deployments
kubectl delete deployment voting-app-onprem --ignore-not-found=true
kubectl delete deployment voting-app-final --ignore-not-found=true
kubectl delete service voting-app-onprem-lb --ignore-not-found=true
kubectl delete service voting-app-final-lb --ignore-not-found=true
kubectl delete configmap voting-app-html --ignore-not-found=true

# Remove the linux-sample if it exists
kubectl delete deployment linux-sample --ignore-not-found=true
kubectl delete service linux-sample --ignore-not-found=true

echo "⏳ Waiting for cleanup to complete..."
sleep 5

echo ""
echo "🚀 Deploying Cat/Dog Voting App..."

# Apply the on-premises version
kubectl apply -f k8s/onprem/voting-app-deployment.yaml

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/voting-app-onprem

echo ""
echo "📊 Checking deployment status..."
kubectl get pods -l app=voting-app-onprem
kubectl get services -l app=voting-app-onprem

echo ""
echo "🌐 Getting service information..."
SERVICE_TYPE=$(kubectl get svc voting-app-onprem-lb -o jsonpath='{.spec.type}' 2>/dev/null || echo "Not found")
if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
    echo "⏳ Waiting for LoadBalancer IP assignment..."
    for i in {1..12}; do
        ONPREM_IP=$(kubectl get svc voting-app-onprem-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$ONPREM_IP" ] && [ "$ONPREM_IP" != "null" ]; then
            echo "✅ LoadBalancer IP assigned: $ONPREM_IP"
            echo "🎯 Your on-premises Cat/Dog Voting App: http://$ONPREM_IP"
            break
        fi
        echo "⏳ Waiting for IP assignment... (attempt $i/12)"
        sleep 10
    done
    
    if [ -z "$ONPREM_IP" ] || [ "$ONPREM_IP" == "null" ]; then
        echo "⚠️  LoadBalancer IP not assigned yet. Checking NodePort..."
        NODE_PORT=$(kubectl get svc voting-app-onprem-lb -o jsonpath='{.spec.ports[0].nodePort}')
        echo "🌐 Access via NodePort: http://<your-node-ip>:$NODE_PORT"
    fi
elif [ "$SERVICE_TYPE" = "NodePort" ]; then
    NODE_PORT=$(kubectl get svc voting-app-onprem-lb -o jsonpath='{.spec.ports[0].nodePort}')
    echo "🌐 NodePort service created. Access via: http://<your-node-ip>:$NODE_PORT"
else
    echo "🌐 ClusterIP service created. Access from within cluster only."
fi

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "🏠 Your Cat/Dog Voting App is now running on your on-premises cluster!"
echo "🔗 Much better than the basic linux-sample.yaml! 🎉"

echo ""
echo "📋 Quick Status Check:"
kubectl get all -l app=voting-app-onprem
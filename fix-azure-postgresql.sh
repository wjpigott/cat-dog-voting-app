#!/bin/bash

echo "🔧 Applying Azure PostgreSQL connection fix..."

# Apply the fixed cross-environment deployment
kubectl apply -f cross-environment-voting-onprem.yaml

# Wait for deployment to start
echo "⏳ Waiting for deployment to update..."
sleep 10

# Check deployment status
echo "📊 Checking deployment status..."
kubectl get deployments -l app=voting-app-onprem
kubectl get pods -l app=voting-app-onprem

# Wait for pod to be ready
echo "⏳ Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=voting-app-onprem --timeout=120s

# Test the fixed Azure connection
echo "🧪 Testing Azure PostgreSQL connection..."
sleep 5

echo "Health check:"
curl -s http://66.242.207.21:31514/health

echo ""
echo "API results (should now show Azure votes):"
curl -s http://66.242.207.21:31514/api/results

echo ""
echo "✅ Azure PostgreSQL fix applied!"
echo "🌐 Check the UI at: http://66.242.207.21:31514"
echo "📊 Azure votes should now show: 4 cats, 3 dogs"
#!/bin/bash

echo "🔄 Restoring the working cross-environment voting app..."

# Deploy the working cross-environment app
kubectl apply -f cross-environment-voting-onprem.yaml

# Wait a moment for the deployment
sleep 5

# Update the service to point to the correct deployment
kubectl patch service voting-app-onprem-service -p '{"spec":{"selector":{"app":"voting-app-onprem"}}}'

# Check the deployment status
echo "📊 Checking deployment status..."
kubectl get deployments -l app=voting-app-onprem
kubectl get pods -l app=voting-app-onprem

# Test the service routing
echo "🔍 Testing service configuration..."
kubectl get service voting-app-onprem-service -o yaml

echo "✅ Deployment complete! The working cross-environment app should be restored."
echo "🌐 Test at: http://66.242.207.21:31514"
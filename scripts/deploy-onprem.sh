#!/bin/bash
# Deploy on-premises voting app with cross-environment functionality

echo "🏠 Deploying on-premises voting app with Azure integration..."

# Apply the deployment
kubectl apply -f onprem-azure-direct-fixed.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/voting-app-onprem-fixed

# Get service information
echo "📊 Service Information:"
kubectl get service voting-app-onprem-fixed-service

echo "✅ On-premises deployment complete!"
echo "🌐 Access your app via NodePort on port 31514"
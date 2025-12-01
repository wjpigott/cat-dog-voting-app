#!/bin/bash
# Deploy Azure voting app with complete UI

echo "🚀 Deploying Azure voting app with complete cross-environment UI..."

# Apply the deployment
kubectl apply -f azure-voting-app-complete.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/azure-voting-app-complete

# Get service information
echo "📊 Service Information:"
kubectl get service azure-voting-app-complete-service

echo "✅ Azure deployment complete!"
echo "🌐 Access your app via the EXTERNAL-IP shown above"
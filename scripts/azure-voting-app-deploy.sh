#!/bin/bash
# Deploy Cat/Dog Voting App to Azure AKS
# Run this in Azure Cloud Shell after PostgreSQL is created

echo "🚀 Deploying Cat/Dog Voting App to Azure AKS"
echo "============================================="

RESOURCE_GROUP="rg-cat-dog-voting-demo"
CLUSTER_NAME="aks-cat-dog-voting"

# Get AKS credentials
echo "🔐 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify connection
echo "✅ Verifying AKS connection..."
kubectl get nodes

# Download the deployment manifest
echo "📥 Downloading voting app manifest..."
wget -O azure-voting-app-with-azure-db.yaml https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/azure-voting-app-with-azure-db.yaml

# Deploy the application
echo "🚀 Deploying voting app..."
kubectl apply -f azure-voting-app-with-azure-db.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/voting-app-azure

# Get service status
echo "🌐 Getting service information..."
kubectl get svc voting-app-azure-service

echo ""
echo "✅ Deployment Complete!"
echo "======================"
echo ""
echo "🔍 Check deployment status:"
echo "kubectl get pods -l app=voting-app-azure"
echo ""
echo "🌐 Get external IP (may take a few minutes):"
echo "kubectl get svc voting-app-azure-service -w"
echo ""
echo "🎯 Once you have the external IP, test your app:"
echo "curl http://YOUR-EXTERNAL-IP/health"
echo "curl http://YOUR-EXTERNAL-IP/api/results"
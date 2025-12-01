#!/bin/bash
# Azure Public IP Discovery Script
# Run this on a machine that can access Azure (or use Azure Cloud Shell)

echo "🔍 Finding Azure Voting App Public Endpoints..."
echo "=============================================="

echo "📋 Method 1: Check AKS LoadBalancer Services"
kubectl get services --all-namespaces -o wide | grep LoadBalancer

echo ""
echo "📋 Method 2: Check Ingress Controllers"
kubectl get ingress --all-namespaces

echo ""
echo "📋 Method 3: Check specific voting app service"
kubectl get service voting-app-service -o wide 2>/dev/null || echo "Service 'voting-app-service' not found"

echo ""
echo "📋 Method 4: Check all services with external IPs"
kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer

echo ""
echo "🌐 Method 5: Check Azure Container Apps (if using)"
echo "az containerapp list --query '[].{name:name,fqdn:properties.configuration.ingress.fqdn}' -o table"

echo ""
echo "🎯 Manual Steps:"
echo "1. Login to Azure Portal"
echo "2. Navigate to your AKS cluster resource group" 
echo "3. Look for Load Balancer with public IP"
echo "4. Or check Container Instances/Container Apps"
echo "5. Test the public IP/URL: curl http://PUBLIC-IP/health"

echo ""
echo "🔧 Expected format for deployment update:"
echo "AZURE_API_URL: http://YOUR-PUBLIC-IP/api/local-results"
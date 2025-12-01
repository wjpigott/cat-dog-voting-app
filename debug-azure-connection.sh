#!/bin/bash

echo "🔍 Checking current deployment logs for Azure connection attempts..."

# Get current pod name
POD_NAME=$(kubectl get pods -l app=voting-app-onprem -o jsonpath='{.items[0].metadata.name}')
echo "Pod name: $POD_NAME"

echo ""
echo "📋 Recent logs (looking for Azure connection attempts):"
kubectl logs $POD_NAME --tail=50

echo ""
echo "🔍 Filtering for Azure-related messages:"
kubectl logs $POD_NAME | grep -i "azure\|postgresql\|postgres\|remote"

echo ""
echo "🧪 Testing current endpoints:"
echo "Health check:"
curl -s http://66.242.207.21:31514/health

echo ""
echo "Current API result:"
curl -s http://66.242.207.21:31514/api/results

echo ""
echo "🎯 Let's test our Azure DB test deployment:"
echo "Deploy Azure DB test:"
echo "kubectl apply -f azure-db-test.yaml"
echo "Then test: curl http://66.242.207.21:31515/test"
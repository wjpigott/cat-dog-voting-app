#!/bin/bash
# Test both environments are working correctly

echo "🧪 Testing cross-environment voting application..."

# Check Azure deployment
echo "🔷 Testing Azure environment..."
AZURE_IP=$(kubectl get service azure-voting-app-complete-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ ! -z "$AZURE_IP" ]; then
    echo "Azure UI: http://$AZURE_IP"
    curl -s "http://$AZURE_IP/api/results" | python3 -m json.tool || echo "❌ Azure API test failed"
else
    echo "❌ Azure external IP not available yet"
fi

echo ""
echo "🏠 Testing on-premises environment..."
# Assuming on-prem is accessible via known IP
ONPREM_IP="66.242.207.21:31514"
echo "OnPrem UI: http://$ONPREM_IP"
curl -s "http://$ONPREM_IP/api/results" | python3 -m json.tool || echo "❌ OnPrem API test failed"

echo ""
echo "✅ Testing complete!"
echo "🌐 Both environments should show combined vote totals"
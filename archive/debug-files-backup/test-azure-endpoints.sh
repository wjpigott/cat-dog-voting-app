#!/bin/bash
# Test Azure Public Endpoints
# Run this on your Linux on-premises machine (66.242.207.21)

echo "🔍 Testing Azure Public Endpoints..."
echo "===================================="

# Test the public IP candidates
ENDPOINTS=(
    "http://52.154.54.110"
    "http://52.154.54.110/health" 
    "http://52.154.54.110/api/local-results"
    "http://catdog-lb-simple.centralus.cloudapp.azure.com"
    "http://catdog-lb-simple.centralus.cloudapp.azure.com/health"
    "http://catdog-lb-simple.centralus.cloudapp.azure.com/api/local-results"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo ""
    echo "🧪 Testing: $endpoint"
    curl -m 10 -I "$endpoint" 2>/dev/null && echo "✅ Reachable" || echo "❌ Not reachable"
done

echo ""
echo "🎯 If any endpoint is reachable, test the API:"
echo "curl http://52.154.54.110/api/local-results"
echo "curl http://catdog-lb-simple.centralus.cloudapp.azure.com/api/local-results"

echo ""
echo "📊 Expected response format:"
echo '{"votes":{"cat":4,"dog":3}}'
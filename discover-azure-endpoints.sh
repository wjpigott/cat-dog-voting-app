# Azure Endpoint Discovery Script
# Run this on your Linux on-premises machine to find the correct Azure endpoints

echo "🔍 Discovering Azure Voting App Endpoints"
echo "========================================"

AZURE_IP="52.154.54.110"
BASE_URL="http://$AZURE_IP"

echo "📊 Testing Azure endpoints at $BASE_URL"
echo ""

# Test common root paths
echo "🌐 Testing root endpoints:"
for path in "/" "/index.html" "/vote" "/results" "/app"; do
    echo -n "  $BASE_URL$path: "
    curl -s -o /dev/null -w "%{http_code}" -m 5 "$BASE_URL$path" && echo " (found)" || echo " (not found)"
done

echo ""

# Test API endpoints
echo "📡 Testing API endpoints:"
for path in "/api" "/api/vote" "/api/votes" "/api/results" "/api/local-results" "/api/health" "/health" "/status"; do
    echo -n "  $BASE_URL$path: "
    curl -s -o /dev/null -w "%{http_code}" -m 5 "$BASE_URL$path" && echo " (found)" || echo " (not found)"
done

echo ""

# Test with different headers
echo "🔧 Testing with different headers:"
curl -s -H "Host: voting-app" "$BASE_URL/" | head -5
echo ""

# Test direct IP without path
echo "📋 Raw response from root:"
curl -s -m 5 "$BASE_URL/" | head -10

echo ""
echo "🎯 Also test the other Azure service:"
echo "curl http://172.169.25.121/ # (if accessible from Azure itself)"

echo ""
echo "🔍 Next steps:"
echo "1. Check which endpoint returns actual content (not 404)"
echo "2. Inspect the Azure deployment YAML to see the configured routes"
echo "3. May need to check if ingress controller is properly configured"
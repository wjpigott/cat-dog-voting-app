# Check service routing and external access to identify why API shows wrong data

echo "🔍 Checking service routing and external API access..."
echo ""

echo "📋 Current services and their endpoints:"
kubectl get services -o wide
echo ""

echo "🔍 Checking which pods are behind each service:"
for service in $(kubectl get services -o jsonpath='{.items[*].metadata.name}'); do
    if [[ $service == *"voting"* ]]; then
        echo "Service: $service"
        kubectl get endpoints $service 2>/dev/null || echo "  No endpoints found"
        echo ""
    fi
done

echo "🧪 Testing external API access (what you're actually calling):"
echo "curl http://66.242.207.21:31514/api/results"
curl http://66.242.207.21:31514/api/results 2>/dev/null || echo "External API call failed"

echo ""
echo "🔍 Checking if there are multiple voting-app deployments:"
kubectl get deployments | grep voting || echo "No voting deployments found"

echo ""
echo "📋 All pods with voting in the name:"
kubectl get pods | grep voting || echo "No voting pods found"

echo ""
echo "💡 The issue might be:"
echo "   1. External traffic hitting a different service"
echo "   2. Multiple deployments running simultaneously"
echo "   3. Service selector pointing to wrong pods"
echo "   4. Load balancer caching old responses"
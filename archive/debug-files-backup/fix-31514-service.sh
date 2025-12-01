# Fix service routing to point port 31514 to the working Azure deployment

echo "🔧 Fixing service routing to point port 31514 to working Azure deployment..."
echo ""

echo "📋 Current service on port 31514:"
kubectl get service voting-app-onprem-service -o yaml

echo ""
echo "🔧 Updating service selector to point to voting-app-azure deployment..."

# Update the existing service to point to the working deployment
kubectl patch service voting-app-onprem-service -p '{"spec":{"selector":{"app":"voting-app-azure"}}}'

echo ""
echo "✅ Service updated! Checking new endpoints..."
kubectl get endpoints voting-app-onprem-service

echo ""
echo "🧪 Testing external API (should now show correct Azure data):"
sleep 5
curl http://66.242.207.21:31514/api/results

echo ""
echo "🎯 Expected result: Azure cats=4, Azure dogs=3"
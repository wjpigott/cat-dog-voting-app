# Fix Port 31514 Deployment Update
# Run these commands on your Linux machine to properly update the existing deployment

echo "🔧 Updating existing deployment on port 31514..."
echo "=============================================="

echo "📊 Step 1: Check current deployment"
kubectl get deployment voting-app-azure
kubectl get service voting-app-service

echo ""
echo "🔄 Step 2: Delete and recreate deployment (keeps same service)"
kubectl delete deployment voting-app-azure

echo "Waiting 10 seconds for cleanup..."
sleep 10

echo ""
echo "🚀 Step 3: Apply updated deployment"
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/updated-onprem-31514.yaml

echo ""
echo "⏳ Step 4: Wait for new pod to start"
sleep 60

echo ""
echo "🧪 Step 5: Test the updated deployment"
echo "Testing health endpoint:"
curl -m 10 http://66.242.207.21:31514/health

echo ""
echo "Testing API results (should show corrected Azure data):"
curl -m 10 http://66.242.207.21:31514/api/results

echo ""
echo "🎯 Expected changes:"
echo "- Azure cats: 1 → 4"  
echo "- Azure dogs: 0 → 3"
echo "- Total votes: 17 → 23"
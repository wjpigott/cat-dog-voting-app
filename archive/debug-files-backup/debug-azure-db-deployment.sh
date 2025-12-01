# Debug Direct Azure DB Deployment
# Run these commands on your Linux on-premises machine to troubleshoot

echo "🔍 Troubleshooting Direct Azure Database Deployment"
echo "=================================================="

echo "📊 Step 1: Check if deployment was applied successfully"
kubectl get deployments | grep voting-app-direct-azure-db

echo ""
echo "📊 Step 2: Check pod status"
kubectl get pods -l app=voting-app-direct-azure-db

echo ""
echo "📊 Step 3: Check service status"
kubectl get service voting-app-direct-azure-db-service

echo ""
echo "📊 Step 4: Check pod logs (if pod exists)"
POD_NAME=$(kubectl get pods -l app=voting-app-direct-azure-db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD_NAME" ]; then
    echo "Pod name: $POD_NAME"
    echo "Recent logs:"
    kubectl logs "$POD_NAME" --tail=20
else
    echo "No pod found - deployment may have failed"
fi

echo ""
echo "📊 Step 5: Check deployment events"
kubectl describe deployment voting-app-direct-azure-db

echo ""
echo "📊 Step 6: Test basic connectivity"
echo "Testing if anything is listening on port 31522..."
curl -m 5 -I http://66.242.207.21:31522/ || echo "Port 31522 not responding"

echo ""
echo "📊 Step 7: Check all NodePort services"
kubectl get services | grep NodePort

echo ""
echo "🔧 Troubleshooting Steps:"
echo "1. If no deployment found: kubectl apply failed"
echo "2. If pod is Pending: Check resource constraints" 
echo "3. If pod is CrashLoopBackOff: Check logs for errors"
echo "4. If service has no endpoints: Pod selector mismatch"
echo "5. If port not responding: Service or pod not ready"

echo ""
echo "🚀 Quick restart if needed:"
echo "kubectl delete deployment voting-app-direct-azure-db"
echo "sleep 5"
echo "kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/voting-app-direct-azure-db.yaml"
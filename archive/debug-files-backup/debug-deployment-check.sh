# Debug Deployment Troubleshooting Commands

echo "🔍 Checking if enhanced debug deployment was applied..."
kubectl get deployments | grep voting-app-debug

echo "📊 Checking pods status..."
kubectl get pods -l app=voting-app-debug

echo "🌐 Checking service status..."
kubectl get service voting-app-debug-service

echo "📝 Checking recent pod logs..."
kubectl logs -l app=voting-app-debug --tail=20

echo "🔧 If pod is not running, check events..."
kubectl describe pod -l app=voting-app-debug

echo "🎯 Quick restart if needed..."
echo "kubectl delete -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/enhanced-debug-onprem.yaml"
echo "sleep 10"
echo "kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/enhanced-debug-onprem.yaml"

echo "⏳ Wait 60 seconds for pod to start, then test:"
echo "curl http://66.242.207.21:31517/health"
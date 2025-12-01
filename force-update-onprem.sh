# Force restart the on-premises voting app deployment to pick up Azure database connection

# Delete the existing deployment and recreate it
kubectl delete deployment voting-app-azure

# Wait a moment
sleep 5

# Apply the new deployment 
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/onprem-azure-direct-deployment.yaml

# Wait for the pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=voting-app-azure --timeout=120s

# Check the pod status
kubectl get pods -l app=voting-app-azure

echo ""
echo "🎯 Deployment updated! Wait 1-2 minutes then test:"
echo "curl http://66.242.207.21:31514/api/results"
echo ""
echo "Expected Azure votes: cats=4, dogs=3"
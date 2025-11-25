#!/bin/bash

echo "🧹 Cleaning up all previous deployments..."

# Delete all existing deployments and services
kubectl delete deployment voting-app --ignore-not-found=true
kubectl delete deployment voting-app-simple --ignore-not-found=true
kubectl delete service voting-app-lb --ignore-not-found=true
kubectl delete service voting-app-simple-lb --ignore-not-found=true
kubectl delete service voting-app-service --ignore-not-found=true
kubectl delete hpa voting-app-hpa --ignore-not-found=true
kubectl delete configmap voting-app-html --ignore-not-found=true

echo "⏳ Waiting for cleanup to complete..."
sleep 10

echo "🚀 Deploying simple voting app..."

# Deploy the final working version
kubectl apply -f k8s/azure/final-voting-app.yaml

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/voting-app-final

echo "🌐 Getting LoadBalancer IP..."
for i in {1..20}; do
  AZURE_IP=$(kubectl get svc voting-app-final-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ -n "$AZURE_IP" ] && [ "$AZURE_IP" != "null" ]; then
    echo "✅ SUCCESS! LoadBalancer IP assigned: $AZURE_IP"
    echo "🎯 Your Cat/Dog Voting App is live at: http://$AZURE_IP"
    break
  fi
  echo "⏳ Waiting for IP assignment... (attempt $i/20)"
  sleep 15
done

echo "📊 Final Status:"
kubectl get pods -l app=voting-app-final
kubectl get services -l app=voting-app-final

if [ -n "$AZURE_IP" ] && [ "$AZURE_IP" != "null" ]; then
    echo ""
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "🌐 Visit your app: http://$AZURE_IP"
    echo "🐱🐶 Start voting for Cats vs Dogs!"
else
    echo "❌ LoadBalancer IP not assigned yet. Check again in a few minutes."
fi
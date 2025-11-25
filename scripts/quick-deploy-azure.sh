#!/bin/bash

echo "🚀 Quick Deploy Cat/Dog Voting App to Azure AKS"

# Set image tag
IMAGE_TAG="ghcr.io/wjpigott/cat-dog-voting-app/cat-dog-voting-app:main"

echo "Using image: $IMAGE_TAG"

# Update the manifest
sed -i "s|image: ghcr.io/wjpigott/cat-dog-voting-app/cat-dog-voting-app:main|image: $IMAGE_TAG|g" k8s/azure/simple-voting-app.yaml

# Create image pull secret (ignore if already exists)
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_ACTOR \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=$GITHUB_ACTOR@users.noreply.github.com \
  --dry-run=client -o yaml | kubectl apply -f - || true

# Clean up any stuck deployments
kubectl delete deployment voting-app --ignore-not-found=true
kubectl delete deployment voting-app-simple --ignore-not-found=true

# Deploy the simple version
kubectl apply -f k8s/azure/simple-voting-app.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to complete..."
kubectl wait --for=condition=available --timeout=300s deployment/voting-app-simple

# Get the LoadBalancer IP
echo "🌐 Getting LoadBalancer IP..."
for i in {1..30}; do
  AZURE_IP=$(kubectl get svc voting-app-simple-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ -n "$AZURE_IP" ] && [ "$AZURE_IP" != "null" ]; then
    echo "✅ LoadBalancer IP assigned: $AZURE_IP"
    echo "🎯 Application URL: http://$AZURE_IP"
    break
  fi
  echo "⏳ Waiting for IP assignment... (attempt $i/30)"
  sleep 10
done

echo "✅ Deployment completed!"
echo "Pod status:"
kubectl get pods -l app=voting-app-simple
kubectl get services -l app=voting-app-simple
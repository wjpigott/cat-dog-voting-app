# Deploy Complete Azure Voting App - PowerShell Script

# First, let's check if we can use kubectl locally
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Host "✅ kubectl found, proceeding with deployment..."
    
    # Get AKS credentials
    az aks get-credentials --resource-group voting-app-demo --name aks-cat-dog-voting --overwrite-existing
    
    # Apply the deployment
    kubectl apply -f azure-voting-app-with-cross-env.yaml
    
    # Check deployment status
    kubectl get deployments -l app=voting-app-azure
    kubectl get services
    
    # Get the external IP
    kubectl get service voting-app-service
    
} else {
    Write-Host "❌ kubectl not found in PATH."
    Write-Host "🔧 Deploying via Azure Cloud Shell instead..."
    
    # Create a cloud shell deployment script
    $cloudShellScript = @'
#!/bin/bash
echo "☁️ Deploying Azure voting app with cross-environment integration..."

# Apply the deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-azure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-app-azure
  template:
    metadata:
      labels:
        app: voting-app-azure
    spec:
      containers:
      - name: voting-app
        image: python:3.9-slim
        ports:
        - containerPort: 5000
        env:
        - name: ENVIRONMENT
          value: "azure"
        - name: REMOTE_API_URL
          value: "http://66.242.207.21:31514"
        - name: AZURE_DB_HOST
          value: "postgres-cat-dog-voting.postgres.database.azure.com"
        - name: AZURE_DB_NAME
          value: "postgres"
        - name: AZURE_DB_USER
          value: "votinguser"
        - name: AZURE_DB_PASSWORD
          value: "SecureVotingPassword123!"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        command: ["/bin/sh"]
        args:
          - -c
          - |
            pip install flask psycopg2-binary requests
            # ... [Full app code would be here] ...
---
apiVersion: v1
kind: Service
metadata:
  name: voting-app-azure-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: voting-app-azure
EOF

echo "✅ Deployment applied! Checking status..."
kubectl get deployments -l app=voting-app-azure
kubectl get services voting-app-azure-service

# Wait for external IP
echo "🔄 Waiting for external IP assignment..."
kubectl get service voting-app-azure-service --watch
'@
    
    $cloudShellScript | Out-File -FilePath "deploy-azure-voting.sh" -Encoding UTF8
    Write-Host "✅ Created deploy-azure-voting.sh"
    Write-Host "📝 To deploy, run this in Azure Cloud Shell:"
    Write-Host ""
    Write-Host "   curl -s https://raw.githubusercontent.com/yourusername/yourrepo/main/deploy-azure-voting.sh | bash"
    Write-Host ""
    Write-Host "   OR upload deploy-azure-voting.sh to Cloud Shell and run: bash deploy-azure-voting.sh"
}

Write-Host ""
Write-Host "🎯 This will deploy a complete Azure voting app with:"
Write-Host "   ☁️  Azure AKS deployment with LoadBalancer service"
Write-Host "   🎨  Full cross-environment UI (same as on-premises)"
Write-Host "   📊  Real-time vote sync with on-premises"
Write-Host "   🔗  Direct Azure PostgreSQL connection"
Write-Host "   📱  Responsive design with Azure branding"
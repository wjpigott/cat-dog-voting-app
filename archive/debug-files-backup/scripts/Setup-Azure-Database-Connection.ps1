# Setup Azure to Connect to On-Premises PostgreSQL Database
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "aks-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$OnPremDatabaseHost = "66.242.207.21",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabasePort = "31514"
)

Write-Host "🔗 Setting up Azure to use On-Premises Database" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Create Azure voting app that connects to on-premises database
$azureVotingAppManifest = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-azure
  labels:
    app: voting-app-azure
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
        image: voting-app-db:latest
        ports:
        - containerPort: 5000
        env:
        - name: VOTE_SOURCE
          value: "azure"
        - name: DB_HOST
          value: "$OnPremDatabaseHost"
        - name: DB_PORT
          value: "$DatabasePort"
        - name: DB_NAME
          value: "voting_app"
        - name: DB_USER
          value: "votinguser"
        - name: DB_PASSWORD
          value: "secure_password_123"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: voting-app-azure-service
spec:
  selector:
    app: voting-app-azure
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
"@

# Create the manifest file
$azureVotingAppManifest | Out-File -FilePath "azure-voting-app-shared-db.yaml" -Encoding UTF8

Write-Host "📝 Created azure-voting-app-shared-db.yaml" -ForegroundColor Green

Write-Host "`n🚀 Deployment Instructions:" -ForegroundColor Yellow
Write-Host "=============================
1. Deploy to Azure AKS:
   az aks get-credentials --resource-group $ResourceGroup --name $ClusterName
   kubectl apply -f azure-voting-app-shared-db.yaml

2. Wait for external IP:
   kubectl get service voting-app-azure-service -w

3. Test Azure environment:
   curl http://[AZURE-EXTERNAL-IP]/health
   curl http://[AZURE-EXTERNAL-IP]/api/results

4. Cast votes from Azure:
   curl -X POST -H 'Content-Type: application/json' -d '{\"choice\":\"cat\"}' http://[AZURE-EXTERNAL-IP]/vote

5. Verify cross-environment data:
   - Azure votes will show source='azure' in database
   - On-premises votes show source='onprem'
   - Both environments share the same vote data!

🎯 Result: True hybrid cloud with shared data store!
" -ForegroundColor White

Write-Host "`n💾 Database Connection Details:" -ForegroundColor Cyan
Write-Host "Host: $OnPremDatabaseHost"
Write-Host "Port: $DatabasePort" 
Write-Host "Database: voting_app"
Write-Host "Username: votinguser"
Write-Host "Password: secure_password_123"

Write-Host "`n⚡ Benefits of This Approach:" -ForegroundColor Green
Write-Host "✅ Single source of truth for all votes"
Write-Host "✅ No data synchronization issues"
Write-Host "✅ Real-time cross-environment vote tracking"
Write-Host "✅ Zero data loss"
Write-Host "✅ Both environments show combined results"
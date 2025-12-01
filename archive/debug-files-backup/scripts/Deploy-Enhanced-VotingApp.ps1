# Enhanced Voting App Deployment Script with PostgreSQL Backend
# This script deploys the database-enabled version of the voting application

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("azure", "onprem", "both")]
    [string]$Environment = "both",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseOption = "shared"  # "shared", "azure-only", "separate"
)

Write-Host "🚀 Deploying Enhanced Voting App with PostgreSQL" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Database Option: $DatabaseOption" -ForegroundColor Cyan

# Build the enhanced Docker image
Write-Host "🔨 Building enhanced Docker image..." -ForegroundColor Yellow
docker build -f Dockerfile-enhanced -t voting-app:enhanced .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully" -ForegroundColor Green

# Deploy based on environment choice
switch ($Environment) {
    "azure" {
        Write-Host "☁️ Deploying to Azure AKS with database..." -ForegroundColor Blue
        
        # Configure kubectl for Azure
        az aks get-credentials --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting
        
        # Deploy to Azure
        kubectl apply -f k8s/voting-app-with-database.yaml
        
        Write-Host "⏳ Waiting for Azure deployment..."
        kubectl wait --for=condition=available --timeout=300s deployment/voting-app-azure
        kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment
        
        # Get Azure service details
        $azureIP = kubectl get service voting-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        Write-Host "🌐 Azure deployment accessible at: http://$azureIP" -ForegroundColor Green
    }
    
    "onprem" {
        Write-Host "🏢 Deploying to On-Premises with database..." -ForegroundColor Green
        
        # Deploy on-premises components only
        kubectl apply -f k8s/voting-app-with-database.yaml
        
        Write-Host "⏳ Waiting for On-Premises deployment..."
        kubectl wait --for=condition=available --timeout=300s deployment/voting-app-onprem
        
        # Get on-premises service details
        $onpremPort = kubectl get service voting-app-onprem-service -o jsonpath='{.spec.ports[0].nodePort}'
        Write-Host "🌐 On-Premises deployment accessible at: http://localhost:$onpremPort" -ForegroundColor Green
    }
    
    "both" {
        Write-Host "🌍 Deploying to both Azure and On-Premises with shared database..." -ForegroundColor Magenta
        
        # Deploy database first
        Write-Host "📊 Deploying shared PostgreSQL database..." -ForegroundColor Cyan
        kubectl apply -f k8s/voting-app-with-database.yaml
        
        Write-Host "⏳ Waiting for database to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment
        
        # Wait a bit more for database initialization
        Start-Sleep 30
        
        Write-Host "⏳ Waiting for all deployments..."
        kubectl wait --for=condition=available --timeout=300s deployment/voting-app-azure
        kubectl wait --for=condition=available --timeout=300s deployment/voting-app-onprem
        
        # Get service details
        Write-Host "🎉 Deployment complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Database Features:" -ForegroundColor Yellow
        Write-Host "  • Persistent vote storage across environments"
        Write-Host "  • Real-time vote tracking by source (Azure/On-Premises)"
        Write-Host "  • Analytics dashboard available at /analytics"
        Write-Host "  • Health monitoring at /health"
        Write-Host ""
        
        # Try to get service IPs
        try {
            $azureIP = kubectl get service voting-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            if ($azureIP) {
                Write-Host "☁️  Azure URL: http://$azureIP" -ForegroundColor Blue
                Write-Host "   Analytics: http://$azureIP/analytics" -ForegroundColor Blue
            } else {
                Write-Host "☁️  Azure: LoadBalancer IP pending..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "☁️  Azure: Service not available" -ForegroundColor Yellow
        }
        
        try {
            $onpremPort = kubectl get service voting-app-onprem-service -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
            if ($onpremPort) {
                Write-Host "🏢 On-Prem URL: http://localhost:$onpremPort" -ForegroundColor Green
                Write-Host "   Analytics: http://localhost:$onpremPort/analytics" -ForegroundColor Green
            } else {
                Write-Host "🏢 On-Premises: Service not available" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "🏢 On-Premises: Service not available" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "📋 Post-Deployment Commands:" -ForegroundColor Cyan
Write-Host "kubectl get pods                    # Check pod status"
Write-Host "kubectl get services                # Check service status"
Write-Host "kubectl logs -f deployment/postgres-deployment  # Check database logs"
Write-Host ""
Write-Host "🧪 Test Database Functionality:" -ForegroundColor Cyan
Write-Host "1. Vote on both environments"
Write-Host "2. Check that votes appear in real-time across both sites"
Write-Host "3. Visit /analytics for detailed breakdown"
Write-Host "4. Scale down one environment and verify votes persist"
Write-Host ""
Write-Host "✅ Enhanced deployment complete!" -ForegroundColor Green
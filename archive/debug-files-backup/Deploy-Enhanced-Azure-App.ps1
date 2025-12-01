param(
    [string]$ResourceGroupName = "rg-cat-dog-voting",
    [string]$AksClusterName = "aks-cat-dog-voting",
    [string]$ManifestFile = "enhanced-azure-voting.yaml"
)

Write-Host "🚀 Deploying Enhanced Azure Voting App..." -ForegroundColor Green

# Install kubectl if not present
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing kubectl..." -ForegroundColor Yellow
    curl.exe -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
    $env:PATH += ";$PWD"
}

# Get AKS credentials using PowerShell Azure module
try {
    Write-Host "🔑 Getting AKS credentials..." -ForegroundColor Yellow
    
    # Try using Az PowerShell module first
    if (Get-Module -ListAvailable -Name Az.Aks) {
        Import-AzAccount -Identity -ErrorAction SilentlyContinue
        $creds = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
        Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $AksClusterName -Force
    }
    else {
        # Fallback to manual kubeconfig setup
        Write-Host "⚠️ Az module not found, using manual kubeconfig..." -ForegroundColor Yellow
        
        # Create basic kubeconfig for AKS
        $kubeconfigPath = "$env:USERPROFILE\.kube\config"
        $kubeconfigDir = Split-Path $kubeconfigPath
        if (-not (Test-Path $kubeconfigDir)) {
            New-Item -ItemType Directory -Path $kubeconfigDir -Force
        }
        
        # This is a placeholder - in practice you'd need the cluster endpoint and certs
        Write-Host "⚠️ Manual kubeconfig setup required. Using alternative deployment..." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ Could not get AKS credentials: $($_.Exception.Message)" -ForegroundColor Red
}

# Check if we have kubectl access
$kubectlWorks = $false
try {
    kubectl cluster-info --request-timeout=5s 2>$null
    if ($LASTEXITCODE -eq 0) {
        $kubectlWorks = $true
        Write-Host "✅ kubectl is working!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️ kubectl not working, will use alternative method" -ForegroundColor Yellow
}

if ($kubectlWorks) {
    Write-Host "🗑️ Removing old deployment..." -ForegroundColor Yellow
    kubectl delete deployment voting-app-azure --ignore-not-found=true
    Start-Sleep -Seconds 5
    
    Write-Host "📁 Deploying enhanced voting app..." -ForegroundColor Yellow
    kubectl apply -f $ManifestFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment started successfully!" -ForegroundColor Green
        
        Write-Host "⏳ Waiting for pod to be ready..." -ForegroundColor Yellow
        for ($i = 1; $i -le 60; $i++) {
            $podStatus = kubectl get pods -l app=voting-app-azure -o jsonpath='{.items[0].status.phase}' 2>$null
            if ($podStatus -eq "Running") {
                Write-Host "✅ Pod is running!" -ForegroundColor Green
                break
            }
            Write-Progress -Activity "Waiting for pod" -Status "Attempt $i/60" -PercentComplete (($i / 60) * 100)
            Start-Sleep -Seconds 5
        }
        
        Write-Host "🌐 Getting service external IP..." -ForegroundColor Yellow
        $externalIP = kubectl get service voting-app-azure-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($externalIP) {
            Write-Host "🎉 Enhanced Azure voting app deployed successfully!" -ForegroundColor Green
            Write-Host "🌍 URL: http://$externalIP" -ForegroundColor Cyan
            Write-Host "🔗 API: http://$externalIP/api/results" -ForegroundColor Cyan
            Write-Host "❤️ Health: http://$externalIP/health" -ForegroundColor Cyan
        } else {
            Write-Host "⏳ External IP not assigned yet, checking service..." -ForegroundColor Yellow
            kubectl get service voting-app-azure-service
        }
    } else {
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
    }
} else {
    Write-Host "🔄 Using alternative deployment method..." -ForegroundColor Yellow
    Write-Host "📝 Enhanced voting app manifest created at: $ManifestFile" -ForegroundColor Green
    Write-Host "💡 To deploy manually:" -ForegroundColor Cyan
    Write-Host "   1. Get AKS credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName" -ForegroundColor White
    Write-Host "   2. Deploy app: kubectl apply -f $ManifestFile" -ForegroundColor White
    Write-Host "   3. Check status: kubectl get pods -l app=voting-app-azure -w" -ForegroundColor White
}

Write-Host "🎯 Enhanced features included:" -ForegroundColor Magenta
Write-Host "  ✨ Beautiful gradient UI matching your on-premises app" -ForegroundColor White
Write-Host "  🗄️ Azure PostgreSQL database connectivity" -ForegroundColor White
Write-Host "  📊 Real-time cross-environment analytics" -ForegroundColor White
Write-Host "  🔄 Auto-refresh results every 30 seconds" -ForegroundColor White
Write-Host "  📱 Mobile-responsive design" -ForegroundColor White
Write-Host "  🎨 Animated vote notifications" -ForegroundColor White
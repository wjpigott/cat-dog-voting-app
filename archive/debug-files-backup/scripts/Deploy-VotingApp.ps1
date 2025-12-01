# Cat/Dog Voting App Deployment Script
# Deploys the application to both on-premises Azure Arc and Azure AKS

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "both", # onprem, azure, or both
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$AksClusterName = "aks-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$ArcClusterName = "arc-cat-dog-voting"
)

Write-Host "🐱🐶 Cat/Dog Voting App Deployment Script" -ForegroundColor Green
Write-Host "Target Environment: $Environment" -ForegroundColor Yellow

# Function to deploy to on-premises Arc cluster
function Deploy-ToOnPrem {
    Write-Host "Deploying to On-Premises Azure Arc Cluster..." -ForegroundColor Blue
    
    try {
        # Check if Arc cluster context is available
        kubectl config get-contexts | Select-String $ArcClusterName
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Azure Arc cluster context '$ArcClusterName' not found. Please ensure cluster is connected."
            return $false
        }
        
        # Update image tag in deployment
        (Get-Content "k8s/onprem/voting-app-deployment.yaml") -replace "image:.*", "image: ghcr.io/$env:GITHUB_REPOSITORY/cat-dog-voting-app:$ImageTag" | Set-Content "k8s/onprem/voting-app-deployment.yaml"
        
        # Apply base manifests
        kubectl apply -f k8s/base/ --context=$ArcClusterName
        if ($LASTEXITCODE -ne 0) { throw "Failed to apply base manifests to Arc cluster" }
        
        # Apply on-premises specific manifests
        kubectl apply -f k8s/onprem/ --context=$ArcClusterName
        if ($LASTEXITCODE -ne 0) { throw "Failed to apply onprem manifests to Arc cluster" }
        
        # Wait for deployment
        kubectl rollout status deployment/voting-app --context=$ArcClusterName --timeout=300s
        if ($LASTEXITCODE -ne 0) { throw "Deployment rollout failed on Arc cluster" }
        
        # Get service endpoint
        $OnPremIP = kubectl get svc voting-app-lb --context=$ArcClusterName -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($OnPremIP) {
            Write-Host "✅ On-Premises deployment successful! Access at: http://$OnPremIP" -ForegroundColor Green
        } else {
            Write-Host "⏳ On-Premises deployment completed. LoadBalancer IP pending..." -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "❌ On-Premises deployment failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to deploy to Azure AKS
function Deploy-ToAzure {
    Write-Host "Deploying to Azure AKS Cluster..." -ForegroundColor Blue
    
    try {
        # Get AKS credentials
        az aks get-credentials --resource-group $ResourceGroup --name $AksClusterName --overwrite-existing
        if ($LASTEXITCODE -ne 0) { throw "Failed to get AKS credentials" }
        
        # Update image tag in deployment
        (Get-Content "k8s/azure/voting-app-deployment.yaml") -replace "image:.*", "image: ghcr.io/$env:GITHUB_REPOSITORY/cat-dog-voting-app:$ImageTag" | Set-Content "k8s/azure/voting-app-deployment.yaml"
        
        # Apply base manifests
        kubectl apply -f k8s/base/
        if ($LASTEXITCODE -ne 0) { throw "Failed to apply base manifests to AKS cluster" }
        
        # Apply Azure specific manifests
        kubectl apply -f k8s/azure/
        if ($LASTEXITCODE -ne 0) { throw "Failed to apply azure manifests to AKS cluster" }
        
        # Wait for deployment
        kubectl rollout status deployment/voting-app --timeout=300s
        if ($LASTEXITCODE -ne 0) { throw "Deployment rollout failed on AKS cluster" }
        
        # Get service endpoint
        $AzureIP = kubectl get svc voting-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($AzureIP) {
            Write-Host "✅ Azure deployment successful! Access at: http://$AzureIP" -ForegroundColor Green
        } else {
            Write-Host "⏳ Azure deployment completed. LoadBalancer IP pending..." -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Error "❌ Azure deployment failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to setup Traffic Manager for load balancing and failover
function Setup-TrafficManager {
    param(
        [string]$OnPremIP,
        [string]$AzureIP
    )
    
    Write-Host "Setting up Traffic Manager for load balancing and failover..." -ForegroundColor Blue
    
    try {
        $ProfileName = "cat-dog-voting-tm"
        $DnsName = "cat-dog-voting-$(Get-Random)"
        
        # Create Traffic Manager profile
        az network traffic-manager profile create `
            --resource-group $ResourceGroup `
            --name $ProfileName `
            --routing-method Priority `
            --unique-dns-name $DnsName `
            --ttl 30
        
        if ($OnPremIP) {
            # Add on-premises endpoint (higher priority)
            az network traffic-manager endpoint create `
                --resource-group $ResourceGroup `
                --profile-name $ProfileName `
                --name onprem-endpoint `
                --type externalEndpoints `
                --target $OnPremIP `
                --priority 1 `
                --endpoint-monitor-path "/health"
        }
        
        if ($AzureIP) {
            # Add Azure endpoint (lower priority for failover)
            az network traffic-manager endpoint create `
                --resource-group $ResourceGroup `
                --profile-name $ProfileName `
                --name azure-endpoint `
                --type externalEndpoints `
                --target $AzureIP `
                --priority 2 `
                --endpoint-monitor-path "/health"
        }
        
        Write-Host "✅ Traffic Manager configured! DNS: $DnsName.trafficmanager.net" -ForegroundColor Green
        return "$DnsName.trafficmanager.net"
    }
    catch {
        Write-Error "❌ Traffic Manager setup failed: $($_.Exception.Message)"
        return $null
    }
}

# Main deployment logic
$OnPremSuccess = $false
$AzureSuccess = $false

switch ($Environment.ToLower()) {
    "onprem" {
        $OnPremSuccess = Deploy-ToOnPrem
    }
    "azure" {
        $AzureSuccess = Deploy-ToAzure
    }
    "both" {
        $OnPremSuccess = Deploy-ToOnPrem
        $AzureSuccess = Deploy-ToAzure
        
        if ($OnPremSuccess -and $AzureSuccess) {
            # Setup load balancing between environments
            Start-Sleep -Seconds 60  # Wait for LoadBalancer IPs
            
            $OnPremIP = kubectl get svc voting-app-lb --context=$ArcClusterName -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            $AzureIP = kubectl get svc voting-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            
            if ($OnPremIP -or $AzureIP) {
                $TrafficManagerDNS = Setup-TrafficManager -OnPremIP $OnPremIP -AzureIP $AzureIP
                if ($TrafficManagerDNS) {
                    Write-Host "🎉 Multi-environment deployment complete!" -ForegroundColor Green
                    Write-Host "Access your application at: http://$TrafficManagerDNS" -ForegroundColor Cyan
                }
            }
        }
    }
    default {
        Write-Error "Invalid environment. Use: onprem, azure, or both"
        exit 1
    }
}

# Summary
Write-Host "`n📊 Deployment Summary:" -ForegroundColor Magenta
Write-Host "On-Premises: $(if($OnPremSuccess){'✅ Success'}else{'❌ Failed'})" -ForegroundColor $(if($OnPremSuccess){'Green'}else{'Red'})
Write-Host "Azure: $(if($AzureSuccess){'✅ Success'}else{'❌ Failed'})" -ForegroundColor $(if($AzureSuccess){'Green'}else{'Red'})

if (-not $OnPremSuccess -and -not $AzureSuccess) {
    exit 1
}
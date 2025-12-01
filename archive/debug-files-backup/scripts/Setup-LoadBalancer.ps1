# Azure Traffic Manager Setup for True Load Balancing
# This creates a single URL that automatically routes between Azure and On-premises

param(
    [Parameter(Mandatory=$true)]
    [string]$TrafficManagerProfile = "cat-dog-voting-tm",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$OnPremPublicIP = "66.242.207.21"
)

Write-Host "🌐 Setting up Azure Traffic Manager for True Load Balancing" -ForegroundColor Green
Write-Host "This will create a single URL that automatically routes between environments" -ForegroundColor Cyan

# Step 1: Create Traffic Manager Profile
Write-Host "📋 Creating Traffic Manager Profile..." -ForegroundColor Yellow
try {
    $tm = az network traffic-manager profile create `
        --name $TrafficManagerProfile `
        --resource-group $ResourceGroup `
        --routing-method Priority `
        --unique-dns-name "cat-dog-voting-$(Get-Random -Minimum 1000 -Maximum 9999)" `
        --output json | ConvertFrom-Json
    
    $tmUrl = $tm.dnsConfig.fqdn
    Write-Host "✅ Traffic Manager created: http://$tmUrl" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Traffic Manager: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Add Azure endpoint (Priority 1 - Primary)
Write-Host "☁️ Adding Azure AKS as primary endpoint..." -ForegroundColor Blue
try {
    az network traffic-manager endpoint create `
        --name "azure-aks-endpoint" `
        --profile-name $TrafficManagerProfile `
        --resource-group $ResourceGroup `
        --type externalEndpoints `
        --target "52.154.54.110" `
        --priority 1 `
        --endpoint-monitor-path "/" `
        --endpoint-monitor-port 80
    
    Write-Host "✅ Azure endpoint added (Priority 1)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to add Azure endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Add On-premises endpoint (Priority 2 - Secondary)  
Write-Host "🏢 Adding On-premises as failover endpoint..." -ForegroundColor Green
try {
    az network traffic-manager endpoint create `
        --name "onprem-endpoint" `
        --profile-name $TrafficManagerProfile `
        --resource-group $ResourceGroup `
        --type externalEndpoints `
        --target "$OnPremPublicIP" `
        --priority 2 `
        --endpoint-monitor-path "/" `
        --endpoint-monitor-port 31514
    
    Write-Host "✅ On-premises endpoint added (Priority 2)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to add on-premises endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Configure health checks
Write-Host "🏥 Configuring health monitoring..." -ForegroundColor Cyan
try {
    az network traffic-manager profile update `
        --name $TrafficManagerProfile `
        --resource-group $ResourceGroup `
        --monitor-interval-seconds 10 `
        --monitor-timeout-seconds 5 `
        --monitor-max-failures 2
    
    Write-Host "✅ Health monitoring configured" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Health monitoring configuration failed" -ForegroundColor Yellow
}

# Step 5: Show status and test URLs
Write-Host ""
Write-Host "🎉 Load Balancer Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌍 Primary URL (Use this for testing): http://$tmUrl" -ForegroundColor Magenta
Write-Host ""
Write-Host "📊 Endpoint Configuration:" -ForegroundColor Yellow
Write-Host "  Priority 1 (Primary):   Azure AKS (52.154.54.110)"
Write-Host "  Priority 2 (Failover):  On-premises ($OnPremPublicIP:31514)"
Write-Host ""
Write-Host "🧪 Failover Testing:" -ForegroundColor Cyan
Write-Host "1. Normal: Traffic goes to Azure (Priority 1)"
Write-Host "2. Azure Down: Traffic automatically routes to On-premises"
Write-Host "3. Azure Restored: Traffic returns to Azure"
Write-Host ""
Write-Host "⏱️ Health Check Settings:" -ForegroundColor Blue
Write-Host "  Check Interval: 10 seconds"
Write-Host "  Timeout: 5 seconds" 
Write-Host "  Max Failures: 2 (6-10 seconds to detect failure)"
Write-Host ""
Write-Host "🔧 Manual Testing Commands:" -ForegroundColor White
Write-Host "# Test Traffic Manager URL"
Write-Host "curl http://$tmUrl"
Write-Host ""
Write-Host "# Scale down Azure to test failover"
Write-Host "kubectl scale deployment voting-app --replicas=0"
Write-Host ""
Write-Host "# Wait 10-20 seconds, then test again"
Write-Host "curl http://$tmUrl  # Should now route to on-premises"
Write-Host ""
Write-Host "# Restore Azure"
Write-Host "kubectl scale deployment voting-app --replicas=3"

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the Traffic Manager URL: http://$tmUrl"
Write-Host "2. Scale down Azure and watch traffic automatically failover"
Write-Host "3. Use this single URL for all your testing!"
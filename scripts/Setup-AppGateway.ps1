# Azure Application Gateway Setup for Cat/Dog Voting App Load Balancing
# This script sets up an App Gateway with backend pools for both environments

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-catdog-voting",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "CentralUS",
    
    [string]$AppGatewayName = "appgw-catdog-voting",
    [string]$VNetName = "vnet-catdog-voting",
    [string]$SubnetName = "appgw-subnet",
    [string]$PublicIPName = "pip-appgw-catdog",
    
    # Backend endpoints
    [string]$AzureBackendIP = "52.154.54.110",
    [string]$OnPremBackendIP = "66.242.207.21",
    [int]$OnPremBackendPort = 31514
)

Write-Host "🌐 Setting up Azure Application Gateway for Cat/Dog Voting App" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Create Virtual Network for App Gateway
Write-Host "📡 Creating Virtual Network..." -ForegroundColor Yellow
az network vnet create `
    --name $VNetName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --address-prefix 10.1.0.0/16 `
    --subnet-name $SubnetName `
    --subnet-prefix 10.1.1.0/24

# Create Public IP for App Gateway
Write-Host "🌍 Creating Public IP..." -ForegroundColor Yellow
az network public-ip create `
    --resource-group $ResourceGroupName `
    --name $PublicIPName `
    --location $Location `
    --allocation-method Static `
    --sku Standard `
    --dns-name "catdog-voting-lb"

# Create Application Gateway
Write-Host "🔗 Creating Application Gateway with Backend Pools..." -ForegroundColor Yellow
az network application-gateway create `
    --name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --vnet-name $VNetName `
    --subnet $SubnetName `
    --public-ip-address $PublicIPName `
    --capacity 2 `
    --sku Standard_v2 `
    --http-settings-cookie-based-affinity Disabled `
    --frontend-port 80 `
    --http-settings-port 80 `
    --http-settings-protocol Http `
    --priority 100

# Add Azure AKS Backend Pool
Write-Host "☁️ Adding Azure AKS Backend Pool..." -ForegroundColor Green
az network application-gateway address-pool create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "azure-backend-pool" `
    --servers $AzureBackendIP

# Add On-Premises Backend Pool
Write-Host "🏠 Adding On-Premises Backend Pool..." -ForegroundColor Green
az network application-gateway address-pool create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "onprem-backend-pool" `
    --servers "${OnPremBackendIP}:${OnPremBackendPort}"

# Create HTTP Settings for On-Premises (port 31514)
Write-Host "⚙️ Creating HTTP Settings for On-Premises..." -ForegroundColor Green
az network application-gateway http-settings create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "onprem-http-settings" `
    --port $OnPremBackendPort `
    --protocol Http `
    --timeout 20 `
    --cookie-based-affinity Disabled

# Create Health Probes
Write-Host "🩺 Creating Health Probes..." -ForegroundColor Green

# Azure health probe
az network application-gateway probe create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "azure-health-probe" `
    --protocol Http `
    --host $AzureBackendIP `
    --path "/" `
    --interval 30 `
    --threshold 3 `
    --timeout 20

# On-premises health probe
az network application-gateway probe create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "onprem-health-probe" `
    --protocol Http `
    --host $OnPremBackendIP `
    --path "/" `
    --interval 30 `
    --threshold 3 `
    --timeout 20 `
    --port $OnPremBackendPort

# Create URL Path Map for Load Balancing (60/40 split suggested)
Write-Host "🔄 Setting up Load Balancing Rules..." -ForegroundColor Green

# Update backend HTTP settings to use health probes
az network application-gateway http-settings update `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "appGatewayBackendHttpSettings" `
    --probe "azure-health-probe"

az network application-gateway http-settings update `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "onprem-http-settings" `
    --probe "onprem-health-probe"

# Create URL Path Map for traffic distribution
az network application-gateway url-path-map create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --name "voting-app-routing" `
    --default-address-pool "azure-backend-pool" `
    --default-http-settings "appGatewayBackendHttpSettings"

# Add path rule for on-premises (this will handle failover scenarios)
az network application-gateway url-path-map rule create `
    --gateway-name $AppGatewayName `
    --resource-group $ResourceGroupName `
    --path-map-name "voting-app-routing" `
    --name "onprem-route" `
    --address-pool "onprem-backend-pool" `
    --http-settings "onprem-http-settings" `
    --paths "/onprem/*"

# Get the public IP address
Write-Host "🎉 Application Gateway Setup Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

$PublicIP = az network public-ip show --resource-group $ResourceGroupName --name $PublicIPName --query ipAddress -o tsv
$FQDN = az network public-ip show --resource-group $ResourceGroupName --name $PublicIPName --query dnsSettings.fqdn -o tsv

Write-Host "📋 Application Gateway Details:" -ForegroundColor Cyan
Write-Host "   • Public IP: $PublicIP" -ForegroundColor White
Write-Host "   • FQDN: $FQDN" -ForegroundColor White
Write-Host "   • Primary Backend: Azure AKS ($AzureBackendIP)" -ForegroundColor White  
Write-Host "   • Secondary Backend: On-Premises ($OnPremBackendIP`:$OnPremBackendPort)" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "🌐 Access your load-balanced app at:" -ForegroundColor Green
Write-Host "   http://$PublicIP" -ForegroundColor Yellow
Write-Host "   http://$FQDN" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "🔧 For manual failover testing:" -ForegroundColor Green
Write-Host "   http://$PublicIP/onprem/ (routes to on-premises)" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# Save configuration for later scripts
$Config = @{
    ResourceGroup = $ResourceGroupName
    AppGatewayName = $AppGatewayName
    PublicIP = $PublicIP
    FQDN = $FQDN
    AzureBackend = $AzureBackendIP
    OnPremBackend = "${OnPremBackendIP}:${OnPremBackendPort}"
} | ConvertTo-Json

$Config | Out-File -FilePath ".\load-balancer-config.json" -Encoding UTF8
Write-Host "💾 Configuration saved to load-balancer-config.json" -ForegroundColor Green
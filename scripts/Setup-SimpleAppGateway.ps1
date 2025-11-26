# Simplified Azure Application Gateway Setup for Cat/Dog Voting App
# This version uses a more direct approach to avoid API issues

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "CentralUS",
    
    [string]$AppGatewayName = "appgw-catdog-voting-simple",
    [string]$VNetName = "vnet-catdog-voting-simple",
    [string]$SubnetName = "appgw-subnet-simple",
    [string]$PublicIPName = "pip-appgw-catdog-simple",
    
    # Backend endpoints
    [string]$AzureBackendIP = "52.154.54.110",
    [string]$OnPremBackendIP = "66.242.207.21",
    [int]$OnPremBackendPort = 31514
)

Write-Host "🌐 Setting up Simplified Azure Application Gateway" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

try {
    # Create Virtual Network for App Gateway
    Write-Host "📡 Creating Virtual Network..." -ForegroundColor Yellow
    az network vnet create `
        --name $VNetName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --address-prefix 10.2.0.0/16 `
        --subnet-name $SubnetName `
        --subnet-prefix 10.2.1.0/24

    # Create Public IP for App Gateway
    Write-Host "🌍 Creating Public IP..." -ForegroundColor Yellow
    az network public-ip create `
        --resource-group $ResourceGroupName `
        --name $PublicIPName `
        --location $Location `
        --allocation-method Static `
        --sku Standard `
        --dns-name "catdog-lb-simple"

    # Create Application Gateway with basic configuration
    Write-Host "🔗 Creating Application Gateway..." -ForegroundColor Yellow
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
        --servers $AzureBackendIP

    Write-Host "✅ Basic Application Gateway created successfully!" -ForegroundColor Green

    # Add the on-premises backend pool
    Write-Host "🏠 Adding On-Premises Backend Pool..." -ForegroundColor Green
    az network application-gateway address-pool create `
        --gateway-name $AppGatewayName `
        --resource-group $ResourceGroupName `
        --name "onprem-backend-pool" `
        --servers $OnPremBackendIP

    # Create HTTP settings for on-premises (port 31514)
    Write-Host "⚙️ Creating HTTP Settings for On-Premises..." -ForegroundColor Green
    az network application-gateway http-settings create `
        --gateway-name $AppGatewayName `
        --resource-group $ResourceGroupName `
        --name "onprem-http-settings" `
        --port $OnPremBackendPort `
        --protocol Http `
        --timeout 20 `
        --cookie-based-affinity Disabled

    # Create a simple routing rule for on-premises
    Write-Host "🔄 Creating On-Premises Routing Rule..." -ForegroundColor Green
    az network application-gateway rule create `
        --gateway-name $AppGatewayName `
        --resource-group $ResourceGroupName `
        --name "onprem-rule" `
        --http-listener "appGatewayHttpListener" `
        --address-pool "onprem-backend-pool" `
        --http-settings "onprem-http-settings" `
        --priority 200

    # Get the public IP address
    $PublicIP = az network public-ip show --resource-group $ResourceGroupName --name $PublicIPName --query ipAddress -o tsv
    $FQDN = az network public-ip show --resource-group $ResourceGroupName --name $PublicIPName --query dnsSettings.fqdn -o tsv

    Write-Host ""
    Write-Host "🎉 Application Gateway Setup Complete!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "📋 Application Gateway Details:" -ForegroundColor Cyan
    Write-Host "   • Public IP: $PublicIP" -ForegroundColor White
    Write-Host "   • FQDN: $FQDN" -ForegroundColor White
    Write-Host "   • Azure Backend: $AzureBackendIP (default)" -ForegroundColor White  
    Write-Host "   • On-Premises Backend: ${OnPremBackendIP}:${OnPremBackendPort}" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Access your load-balanced app at:" -ForegroundColor Green
    Write-Host "   http://$PublicIP" -ForegroundColor Yellow
    Write-Host "   http://$FQDN" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 Manual Failover Testing:" -ForegroundColor Green
    Write-Host "   1. Scale down Azure AKS: kubectl scale deployment voting-app --replicas=0" -ForegroundColor Cyan
    Write-Host "   2. App Gateway will detect failure and route to on-premises" -ForegroundColor Cyan
    Write-Host "   3. Scale Azure back up: kubectl scale deployment voting-app --replicas=2" -ForegroundColor Cyan
    Write-Host ""

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

} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 You can manually configure load balancing by:" -ForegroundColor Yellow
    Write-Host "   1. Using your existing Azure Load Balancer or Traffic Manager" -ForegroundColor White
    Write-Host "   2. Setting up DNS round-robin between:" -ForegroundColor White
    Write-Host "      - Azure: http://52.154.54.110" -ForegroundColor Cyan
    Write-Host "      - On-Prem: http://66.242.207.21:31514" -ForegroundColor Cyan
}
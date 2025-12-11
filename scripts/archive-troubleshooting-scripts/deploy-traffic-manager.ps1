# Azure Traffic Manager Deployment Script (PowerShell)
# Deploys Traffic Manager with automatic failover between Azure AKS and On-Premises

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$Location = "Central US",
    [string]$AzureEndpoint = "52.154.54.110",
    [string]$OnPremEndpoint = "66.242.207.21",
    [int]$OnPremPort = 31514
)

$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "🚀 Azure Traffic Manager Deployment Script" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray

# Function to test endpoint health
function Test-EndpointHealth {
    param([string]$Endpoint, [string]$Name)
    
    Write-Host "🔍 Testing $Name endpoint: $Endpoint" -ForegroundColor Blue
    try {
        $response = Invoke-WebRequest -Uri $Endpoint -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ $Name is healthy (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "⚠️  $Name is not responding: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check Azure CLI login
function Test-AzureLogin {
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Host "✅ Already logged into Azure CLI" -ForegroundColor Green
            Write-Host "📋 Current account: $($account.name)" -ForegroundColor Cyan
            return $true
        }
    }
    catch {
        Write-Host "⚠️  Not logged into Azure CLI" -ForegroundColor Yellow
        Write-Host "🔑 Please run: az login" -ForegroundColor Blue
        return $false
    }
}

# Function to ensure resource group exists
function Ensure-ResourceGroup {
    param([string]$RgName, [string]$RgLocation)
    
    Write-Host "🔄 Checking resource group: $RgName" -ForegroundColor Blue
    $rg = az group show --name $RgName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "📁 Creating resource group: $RgName" -ForegroundColor Yellow
        az group create --name $RgName --location $RgLocation --output table
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Resource group created" -ForegroundColor Green
        } else {
            throw "Failed to create resource group"
        }
    } else {
        Write-Host "✅ Resource group exists" -ForegroundColor Green
    }
}

# Function to create Traffic Manager profile
function New-TrafficManagerProfile {
    param([string]$RgName, [string]$ProfileName)
    
    Write-Host "🌐 Creating Traffic Manager profile: $ProfileName" -ForegroundColor Blue
    
    az network traffic-manager profile create `
        --resource-group $RgName `
        --name $ProfileName `
        --routing-method Priority `
        --unique-dns-name $ProfileName `
        --ttl 30 `
        --protocol HTTP `
        --port 80 `
        --path "/" `
        --interval 30 `
        --timeout 10 `
        --max-failures 3 `
        --output table
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Traffic Manager profile created" -ForegroundColor Green
    } else {
        throw "Failed to create Traffic Manager profile"
    }
}

# Function to add endpoints
function Add-TrafficManagerEndpoints {
    param([string]$RgName, [string]$ProfileName, [string]$AzureTarget, [string]$OnPremTarget)
    
    Write-Host "🎯 Adding Azure AKS endpoint (Primary)" -ForegroundColor Blue
    az network traffic-manager endpoint create `
        --resource-group $RgName `
        --profile-name $ProfileName `
        --name "azure-aks-primary" `
        --type externalEndpoints `
        --target $AzureTarget `
        --priority 1 `
        --endpoint-status Enabled `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure endpoint added" -ForegroundColor Green
    } else {
        throw "Failed to add Azure endpoint"
    }

    Write-Host "🏠 Adding OnPrem endpoint (Backup)" -ForegroundColor Blue
    az network traffic-manager endpoint create `
        --resource-group $RgName `
        --profile-name $ProfileName `
        --name "onprem-backup" `
        --type externalEndpoints `
        --target $OnPremTarget `
        --priority 2 `
        --endpoint-status Enabled `
        --output table

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ OnPrem endpoint added" -ForegroundColor Green
    } else {
        throw "Failed to add OnPrem endpoint"
    }
}

# Function to show deployment results
function Show-DeploymentResults {
    param([string]$RgName, [string]$ProfileName, [string]$AzureTarget, [string]$OnPremTarget, [int]$OnPremPort)
    
    Write-Host "`n🎉 Traffic Manager Deployment Complete!" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Gray
    
    # Get the FQDN
    $fqdn = az network traffic-manager profile show `
        --resource-group $RgName `
        --name $ProfileName `
        --query "dnsConfig.fqdn" `
        --output tsv
    
    Write-Host "🌐 Your Traffic Manager URL:" -ForegroundColor Green
    Write-Host "   http://$fqdn" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📊 Endpoint Configuration:" -ForegroundColor Green
    Write-Host "   Primary: $AzureTarget (Azure AKS - Priority 1)" -ForegroundColor Cyan
    Write-Host "   Backup:  $OnPremTarget`:$OnPremPort (OnPrem K3s - Priority 2)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚡ Failover Configuration:" -ForegroundColor Green
    Write-Host "   - Health checks every 30 seconds" -ForegroundColor Cyan
    Write-Host "   - 3 failures trigger automatic failover" -ForegroundColor Cyan
    Write-Host "   - 10 second timeout per check" -ForegroundColor Cyan
    Write-Host "   - Priority routing: Azure first, OnPrem backup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🧪 Test your setup:" -ForegroundColor Yellow
    Write-Host "   curl http://$fqdn" -ForegroundColor Cyan
    Write-Host "   # Should route to Azure when healthy" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔄 Test failover:" -ForegroundColor Yellow
    Write-Host "   1. Shut down AKS cluster" -ForegroundColor Cyan
    Write-Host "   2. Wait 2-3 minutes for health check failures" -ForegroundColor Cyan
    Write-Host "   3. Access URL - should route to OnPrem" -ForegroundColor Cyan
    Write-Host "   4. Start AKS - should fail back automatically" -ForegroundColor Cyan
}

# Main execution
try {
    Write-Host "📋 Configuration:" -ForegroundColor Blue
    Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Cyan
    Write-Host "   Profile Name: $ProfileName" -ForegroundColor Cyan
    Write-Host "   Azure Endpoint: $AzureEndpoint" -ForegroundColor Cyan
    Write-Host "   OnPrem Endpoint: $OnPremEndpoint`:$OnPremPort" -ForegroundColor Cyan
    Write-Host ""

    # Test endpoints first
    Write-Host "🔍 Testing endpoint health..." -ForegroundColor Blue
    $azureHealthy = Test-EndpointHealth -Endpoint "http://$AzureEndpoint" -Name "Azure AKS"
    $onpremHealthy = Test-EndpointHealth -Endpoint "http://$OnPremEndpoint`:$OnPremPort" -Name "OnPrem K3s"
    Write-Host ""

    # Check Azure login
    if (-not (Test-AzureLogin)) {
        Write-Host "❌ Please login to Azure CLI first: az login" -ForegroundColor Red
        exit 1
    }

    # Deploy Traffic Manager
    Ensure-ResourceGroup -RgName $ResourceGroup -RgLocation $Location
    New-TrafficManagerProfile -RgName $ResourceGroup -ProfileName $ProfileName
    Add-TrafficManagerEndpoints -RgName $ResourceGroup -ProfileName $ProfileName -AzureTarget $AzureEndpoint -OnPremTarget $OnPremEndpoint
    
    # Show results
    Show-DeploymentResults -RgName $ResourceGroup -ProfileName $ProfileName -AzureTarget $AzureEndpoint -OnPremTarget $OnPremEndpoint -OnPremPort $OnPremPort

} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   1. Ensure Azure CLI is installed and logged in" -ForegroundColor Gray
    Write-Host "   2. Check network connectivity to endpoints" -ForegroundColor Gray
    Write-Host "   3. Verify resource group permissions" -ForegroundColor Gray
    exit 1
}
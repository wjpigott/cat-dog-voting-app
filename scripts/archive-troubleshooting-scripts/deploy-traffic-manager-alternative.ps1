# Azure Traffic Manager Deployment - Alternative Approach
# Uses alternative methods when Azure CLI has permission issues

param(
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)",
    [switch]$UsePortable
)

Write-Host "🚀 TRAFFIC MANAGER DEPLOYMENT - ALTERNATIVE APPROACH" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray

# Function to test endpoints
function Test-Endpoints {
    Write-Host "🔍 Testing endpoints health..." -ForegroundColor Cyan
    
    $azureStatus = $false
    $onpremStatus = $false
    
    try {
        $response = Invoke-WebRequest -Uri "http://52.154.54.110" -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ Azure AKS: Online (Status: $($response.StatusCode))" -ForegroundColor Green
        $azureStatus = $true
    }
    catch {
        Write-Host "❌ Azure AKS: Offline" -ForegroundColor Red
    }
    
    try {
        $response = Invoke-WebRequest -Uri "http://66.242.207.21:31514" -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ OnPrem K3s: Online (Status: $($response.StatusCode))" -ForegroundColor Green
        $onpremStatus = $true
    }
    catch {
        Write-Host "❌ OnPrem K3s: Offline" -ForegroundColor Red
    }
    
    return @{Azure = $azureStatus; OnPrem = $onpremStatus}
}

# Function to download and use portable Azure CLI
function Use-PortableAzureCLI {
    Write-Host "📥 Setting up portable Azure CLI..." -ForegroundColor Cyan
    
    $portableDir = ".\azure-cli-portable"
    if (-not (Test-Path $portableDir)) {
        Write-Host "⬇️ Downloading portable Azure CLI..." -ForegroundColor Yellow
        # Create a basic Azure CLI wrapper using REST API calls
        New-Item -Path $portableDir -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "⚠️ Portable CLI not fully implemented. Using alternative methods..." -ForegroundColor Yellow
    return $false
}

# Function to deploy using Azure PowerShell
function Deploy-UsingAzPowerShell {
    Write-Host "🔄 Attempting deployment with Azure PowerShell..." -ForegroundColor Cyan
    
    # Check if Az module is available
    if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
        Write-Host "📦 Installing Azure PowerShell module..." -ForegroundColor Yellow
        try {
            Install-Module -Name Az.Resources -Force -AllowClobber -Scope CurrentUser
            Write-Host "✅ Azure PowerShell installed" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to install Azure PowerShell: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    # Import module
    Import-Module Az.Resources -Force
    
    # Connect to Azure
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "🔑 Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
        }
        else {
            Write-Host "✅ Already connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Azure PowerShell connection failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Deploy Traffic Manager
    try {
        Write-Host "🌐 Deploying Traffic Manager: $ProfileName" -ForegroundColor Green
        
        # Ensure resource group exists
        Write-Host "📦 Creating resource group if needed..." -ForegroundColor Cyan
        $rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $rg) {
            New-AzResourceGroup -Name $ResourceGroup -Location "Central US" -Force
            Write-Host "✅ Resource group created" -ForegroundColor Green
        }
        else {
            Write-Host "✅ Resource group exists" -ForegroundColor Green
        }
        
        $templateParams = @{
            profileName = $ProfileName
            azureEndpoint = "52.154.54.110"
            onpremEndpoint = "66.242.207.21"
            onpremPort = 31514
        }
        
        $deployment = New-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroup `
            -TemplateFile "azure-traffic-manager.json" `
            -TemplateParameterObject $templateParams `
            -Verbose
        
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Host "✅ TRAFFIC MANAGER DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
            $url = $deployment.Outputs.trafficManagerUrl.Value
            Write-Host "🌐 Your global URL: $url" -ForegroundColor Magenta
            
            # Start monitoring
            Start-Process PowerShell -ArgumentList "-File .\scripts\monitor-traffic-manager.ps1 -TrafficManagerUrl `"$url`""
            return $true
        }
        else {
            Write-Host "❌ Deployment failed: $($deployment.ProvisioningState)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Deployment error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create manual deployment package
function Create-ManualDeployment {
    Write-Host "📋 Creating manual deployment package..." -ForegroundColor Cyan
    
    $deploymentScript = @"
# MANUAL AZURE TRAFFIC MANAGER DEPLOYMENT
# Copy and paste this into Azure Cloud Shell (https://shell.azure.com)

# Set variables
RESOURCE_GROUP="$ResourceGroup"
PROFILE_NAME="$ProfileName"
AZURE_ENDPOINT="52.154.54.110"
ONPREM_ENDPOINT="66.242.207.21"

# Create resource group
az group create --name \$RESOURCE_GROUP --location centralus

# Create Traffic Manager profile
az network traffic-manager profile create \\
    --resource-group \$RESOURCE_GROUP \\
    --name \$PROFILE_NAME \\
    --routing-method Priority \\
    --unique-dns-name \$PROFILE_NAME \\
    --ttl 30 \\
    --protocol HTTP \\
    --port 80 \\
    --path "/" \\
    --interval 30 \\
    --timeout 10 \\
    --max-failures 3

# Add Azure endpoint (Primary)
az network traffic-manager endpoint create \\
    --resource-group \$RESOURCE_GROUP \\
    --profile-name \$PROFILE_NAME \\
    --name azure-aks-primary \\
    --type externalEndpoints \\
    --target \$AZURE_ENDPOINT \\
    --priority 1 \\
    --endpoint-status Enabled

# Add OnPrem endpoint (Backup)
az network traffic-manager endpoint create \\
    --resource-group \$RESOURCE_GROUP \\
    --profile-name \$PROFILE_NAME \\
    --name onprem-backup \\
    --type externalEndpoints \\
    --target \$ONPREM_ENDPOINT \\
    --priority 2 \\
    --endpoint-status Enabled

# Show the Traffic Manager URL
echo "✅ TRAFFIC MANAGER DEPLOYED!"
echo "🌐 URL: http://\$PROFILE_NAME.trafficmanager.net"
"@
    
    $scriptFile = "deploy-traffic-manager-cloudshell.sh"
    $deploymentScript | Out-File -FilePath $scriptFile -Encoding UTF8
    
    Write-Host "✅ Manual deployment script created: $scriptFile" -ForegroundColor Green
    Write-Host "🌐 Copy the script content and run in Azure Cloud Shell: https://shell.azure.com" -ForegroundColor Cyan
    Write-Host "📋 Your Traffic Manager URL will be: http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta
}

# Main execution
Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "   Profile Name: $ProfileName" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "   Future URL: http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta

# Test endpoints first
$endpointStatus = Test-Endpoints
if (-not $endpointStatus.Azure -and -not $endpointStatus.OnPrem) {
    Write-Host "❌ Both endpoints are down. Cannot deploy Traffic Manager." -ForegroundColor Red
    exit 1
}

# Try different deployment methods in order
Write-Host "`n🚀 Attempting deployment..." -ForegroundColor Green

# Method 1: Azure PowerShell
if (Deploy-UsingAzPowerShell) {
    Write-Host "✅ Deployed using Azure PowerShell!" -ForegroundColor Green
    exit 0
}

# Method 2: Portable Azure CLI (if requested)
if ($UsePortable) {
    if (Use-PortableAzureCLI) {
        Write-Host "✅ Deployed using portable Azure CLI!" -ForegroundColor Green
        exit 0
    }
}

# Method 3: Manual deployment
Write-Host "📋 Creating manual deployment package..." -ForegroundColor Yellow
Create-ManualDeployment

Write-Host "`n📌 NEXT STEPS:" -ForegroundColor Magenta
Write-Host "1. Open Azure Cloud Shell: https://shell.azure.com" -ForegroundColor White
Write-Host "2. Copy and run the generated script" -ForegroundColor White
Write-Host "3. Test with: .\scripts\test-failover-tm.sh `"http://$ProfileName.trafficmanager.net`"" -ForegroundColor White
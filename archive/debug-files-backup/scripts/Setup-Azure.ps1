# Azure Setup Script for Cat/Dog Voting App
# This script helps set up Azure resources and service principal for GitHub Actions

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$AksClusterName = "aks-cat-dog-voting"
)

Write-Host "🚀 Setting up Azure resources for Cat/Dog Voting App..." -ForegroundColor Green

# Login to Azure
Write-Host "Logging into Azure..." -ForegroundColor Yellow
az login

# Set subscription
az account set --subscription $SubscriptionId
Write-Host "✅ Using subscription: $SubscriptionId" -ForegroundColor Green

# Create resource group
Write-Host "Creating resource group: $ResourceGroupName..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location
Write-Host "✅ Resource group created" -ForegroundColor Green

# Create AKS cluster
Write-Host "Creating AKS cluster: $AksClusterName (this may take 10-15 minutes)..." -ForegroundColor Yellow
az aks create `
    --resource-group $ResourceGroupName `
    --name $AksClusterName `
    --node-count 3 `
    --node-vm-size Standard_DS2_v2 `
    --enable-addons monitoring `
    --generate-ssh-keys `
    --enable-managed-identity

Write-Host "✅ AKS cluster created" -ForegroundColor Green

# Create service principal for GitHub Actions
Write-Host "Creating service principal for GitHub Actions..." -ForegroundColor Yellow

$scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
$spOutput = az ad sp create-for-rbac --name "sp-cat-dog-voting-github" --role Contributor --scopes $scope --sdk-auth | ConvertFrom-Json

Write-Host "✅ Service principal created" -ForegroundColor Green

# Output the values needed for GitHub
Write-Host "`n🔐 GitHub Repository Configuration" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta

Write-Host "`n📝 Repository Secrets (add these to GitHub repo > Settings > Secrets and variables > Actions):" -ForegroundColor Cyan
Write-Host "AZURE_CREDENTIALS=" -ForegroundColor White -NoNewline
Write-Host ($spOutput | ConvertTo-Json -Depth 10 -Compress) -ForegroundColor Yellow

Write-Host "`nAZURE_CLIENT_SECRET=" -ForegroundColor White -NoNewline
Write-Host $spOutput.clientSecret -ForegroundColor Yellow

Write-Host "`n📋 Repository Variables (add these to GitHub repo > Settings > Secrets and variables > Actions > Variables):" -ForegroundColor Cyan
Write-Host "AZURE_RG=" -ForegroundColor White -NoNewline
Write-Host $ResourceGroupName -ForegroundColor Yellow

Write-Host "AKS_CLUSTER_NAME=" -ForegroundColor White -NoNewline
Write-Host $AksClusterName -ForegroundColor Yellow

Write-Host "AZURE_CLIENT_ID=" -ForegroundColor White -NoNewline
Write-Host $spOutput.clientId -ForegroundColor Yellow

Write-Host "AZURE_TENANT_ID=" -ForegroundColor White -NoNewline
Write-Host $spOutput.tenantId -ForegroundColor Yellow

Write-Host "AZURE_SUBSCRIPTION_ID=" -ForegroundColor White -NoNewline
Write-Host $spOutput.subscriptionId -ForegroundColor Yellow

# Save to file for reference
$configFile = "azure-github-config.json"
@{
    secrets = @{
        AZURE_CREDENTIALS = ($spOutput | ConvertTo-Json -Depth 10)
        AZURE_CLIENT_SECRET = $spOutput.clientSecret
    }
    variables = @{
        AZURE_RG = $ResourceGroupName
        AKS_CLUSTER_NAME = $AksClusterName
        AZURE_CLIENT_ID = $spOutput.clientId
        AZURE_TENANT_ID = $spOutput.tenantId
        AZURE_SUBSCRIPTION_ID = $spOutput.subscriptionId
    }
} | ConvertTo-Json -Depth 10 | Out-File $configFile

Write-Host "`n💾 Configuration saved to: $configFile" -ForegroundColor Green
Write-Host "`n🎯 Next Steps:" -ForegroundColor Magenta
Write-Host "1. Copy the secrets and variables above to your GitHub repository" -ForegroundColor White
Write-Host "2. Set up your on-premises Azure Arc cluster" -ForegroundColor White
Write-Host "3. Run the deployment pipeline!" -ForegroundColor White

Write-Host "`n🔗 GitHub Repository: https://github.com/wjpigott/cat-dog-voting-app" -ForegroundColor Cyan
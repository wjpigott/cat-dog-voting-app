# Azure Traffic Manager - REST API Deployment
# Alternative deployment method using Azure REST API

param(
    [string]$SubscriptionId = "",
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"
)

Write-Host "🚀 Azure Traffic Manager - REST API Deployment" -ForegroundColor Green

if ([string]::IsNullOrEmpty($SubscriptionId)) {
    Write-Host "⚠️  Subscription ID required for REST API deployment" -ForegroundColor Yellow
    Write-Host "Please provide your Azure subscription ID:" -ForegroundColor Gray
    Write-Host "Example: .\deploy-traffic-manager-rest.ps1 -SubscriptionId 'your-subscription-id'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "📍 To find your subscription ID:" -ForegroundColor Cyan
    Write-Host "1. Go to https://portal.azure.com" -ForegroundColor White
    Write-Host "2. Search for 'Subscriptions'" -ForegroundColor White
    Write-Host "3. Copy the Subscription ID" -ForegroundColor White
    exit 1
}

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow  
Write-Host "Profile Name: $ProfileName" -ForegroundColor Yellow
Write-Host "Traffic Manager URL will be: http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta

Write-Host "`n🔑 Authentication Required" -ForegroundColor Yellow
Write-Host "This script requires Azure authentication." -ForegroundColor Gray
Write-Host "Please use one of these methods:" -ForegroundColor Gray
Write-Host ""
Write-Host "METHOD 1: Manual Portal Deployment (Recommended)" -ForegroundColor Green
Write-Host "Run: .\scripts\deploy-traffic-manager-manual.ps1" -ForegroundColor White
Write-Host ""
Write-Host "METHOD 2: Azure CLI (if permissions fixed)" -ForegroundColor Yellow
Write-Host "Run PowerShell as Administrator, then:" -ForegroundColor White
Write-Host "az deployment group create --resource-group $ResourceGroup --template-file azure-traffic-manager.json" -ForegroundColor DarkGray
Write-Host ""
Write-Host "METHOD 3: Azure PowerShell" -ForegroundColor Cyan
Write-Host "Install Azure PowerShell, then:" -ForegroundColor White
Write-Host "Install-Module -Name Az -Force" -ForegroundColor DarkGray
Write-Host "Connect-AzAccount" -ForegroundColor DarkGray
Write-Host "New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile azure-traffic-manager.json" -ForegroundColor DarkGray

Write-Host "`n✨ IMMEDIATE ACCESS (While setting up Traffic Manager):" -ForegroundColor Magenta
Write-Host "OnPrem endpoint is working: http://66.242.207.21:31514/" -ForegroundColor Green
Write-Host "Test it now while your AKS cluster starts up!" -ForegroundColor Yellow
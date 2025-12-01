# Quick Azure Traffic Manager Deployment - Portal Based
# Opens Azure portal with pre-configured Traffic Manager deployment

$ResourceGroup = "rg-cat-dog-voting"
$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"
$AzureEndpoint = "52.154.54.110"
$OnPremEndpoint = "66.242.207.21"

Write-Host "🚀 DEPLOYING TRAFFIC MANAGER VIA AZURE PORTAL" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Gray

# Create the template URI for direct deployment
$templateUri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.network/traffic-manager-external-endpoint/azuredeploy.json"

# Parameters for the deployment
$params = @{
    profileName = $ProfileName
    endpoint1Name = "azure-aks-primary"
    endpoint1Target = $AzureEndpoint
    endpoint1Priority = 1
    endpoint2Name = "onprem-backup" 
    endpoint2Target = $OnPremEndpoint
    endpoint2Priority = 2
}

Write-Host "📋 Traffic Manager Configuration:" -ForegroundColor Cyan
Write-Host "   Profile Name: $ProfileName" -ForegroundColor Yellow
Write-Host "   Global URL: http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta
Write-Host "   Primary: $AzureEndpoint (Priority 1)" -ForegroundColor Green
Write-Host "   Backup: $OnPremEndpoint (Priority 2)" -ForegroundColor Yellow

# Create Azure portal deployment URL
$deploymentUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwjpigott%2Fcat-dog-voting-app%2Fmain%2Fazure-traffic-manager.json"

Write-Host "`n🌐 DEPLOYING NOW..." -ForegroundColor Magenta
Write-Host "Opening Azure portal deployment..." -ForegroundColor Gray

# Try to deploy using REST API approach first
try {
    Write-Host "🔑 Attempting direct deployment..." -ForegroundColor Blue
    
    # Check if we can use Azure PowerShell
    if (Get-Module -ListAvailable -Name Az.Resources) {
        Write-Host "✅ Using Azure PowerShell..." -ForegroundColor Green
        Import-Module Az.Resources -Force
        
        if (-not (Get-AzContext)) {
            Connect-AzAccount
        }
        
        $templateFile = "azure-traffic-manager.json"
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $templateFile -profileName $ProfileName
        
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Host "✅ TRAFFIC MANAGER DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
            Write-Host "🌐 Your global URL: $($deployment.Outputs.trafficManagerUrl.Value)" -ForegroundColor Magenta
            exit 0
        }
    }
}
catch {
    Write-Host "⚠️ Azure PowerShell not available, using portal deployment..." -ForegroundColor Yellow
}

Write-Host "🌐 Opening Azure Portal for manual deployment..." -ForegroundColor Cyan
Start-Process $deploymentUrl

Write-Host "`n📋 MANUAL DEPLOYMENT STEPS:" -ForegroundColor Magenta
Write-Host "1. The Azure portal should open automatically" -ForegroundColor White
Write-Host "2. Use these values in the deployment form:" -ForegroundColor White
Write-Host "   - Profile Name: $ProfileName" -ForegroundColor Yellow
Write-Host "   - Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "   - Azure Endpoint: $AzureEndpoint" -ForegroundColor Yellow
Write-Host "   - OnPrem Endpoint: $OnPremEndpoint" -ForegroundColor Yellow
Write-Host "3. Click 'Review + Create' then 'Create'" -ForegroundColor White

Write-Host "`n✅ YOUR FINAL TRAFFIC MANAGER URL WILL BE:" -ForegroundColor Green
Write-Host "http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta

Write-Host "`n🧪 TESTING AFTER DEPLOYMENT:" -ForegroundColor Cyan
Write-Host "Run this command when deployment completes:" -ForegroundColor Gray
Write-Host ".\scripts\test-failover-tm.sh `"http://$ProfileName.trafficmanager.net`"" -ForegroundColor DarkGray
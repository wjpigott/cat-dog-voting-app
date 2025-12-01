# Direct Azure REST API Traffic Manager Deployment
# Uses PowerShell Invoke-RestMethod to deploy Traffic Manager directly

param(
    [string]$SubscriptionId,
    [string]$AccessToken
)

$ResourceGroup = "rg-cat-dog-voting"
$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "🚀 DIRECT REST API DEPLOYMENT" -ForegroundColor Green

if (-not $SubscriptionId) {
    Write-Host "⚠️ For direct deployment, you need:" -ForegroundColor Yellow
    Write-Host "1. Your Azure Subscription ID" -ForegroundColor Gray
    Write-Host "2. An access token" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🌐 EASIER: Use the Azure Portal deployment that just opened!" -ForegroundColor Cyan
    Write-Host "Or install Azure PowerShell:" -ForegroundColor Gray
    Write-Host "Install-Module -Name Az -AllowClobber -Force" -ForegroundColor DarkGray
    exit 1
}

# ARM Template for Traffic Manager
$template = @{
    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = @{
        profileName = @{
            type = "string"
            defaultValue = $ProfileName
        }
    }
    resources = @(
        @{
            type = "Microsoft.Network/trafficManagerProfiles"
            apiVersion = "2022-04-01"
            name = "[parameters('profileName')]"
            location = "global"
            properties = @{
                profileStatus = "Enabled"
                trafficRoutingMethod = "Priority"
                dnsConfig = @{
                    relativeName = "[parameters('profileName')]"
                    ttl = 30
                }
                monitorConfig = @{
                    protocol = "HTTP"
                    port = 80
                    path = "/"
                    intervalInSeconds = 30
                    toleratedNumberOfFailures = 3
                    timeoutInSeconds = 10
                }
            }
        }
    )
    outputs = @{
        trafficManagerFqdn = @{
            type = "string"
            value = "[reference(resourceId('Microsoft.Network/trafficManagerProfiles', parameters('profileName'))).dnsConfig.fqdn]"
        }
    }
}

Write-Host "📋 Template created for: $ProfileName" -ForegroundColor Cyan
Write-Host "🌐 Would deploy to: http://$ProfileName.trafficmanager.net" -ForegroundColor Magenta

Write-Host "`n✨ RECOMMENDED: Complete the Azure Portal deployment instead!" -ForegroundColor Green
Write-Host "The portal deployment is easier and more reliable." -ForegroundColor Gray
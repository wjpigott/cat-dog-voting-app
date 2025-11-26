# Failover Testing Script for Cat/Dog Voting App
# Run this script to test failover scenarios

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("azure", "onprem", "restore")]
    [string]$Action
)

$AzureEndpoint = "http://52.154.54.110"
$OnPremEndpoint = "http://66.242.207.21:31514"

function Test-Endpoint {
    param($Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ $Url - Status: $($response.StatusCode)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ $Url - Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "🔄 Failover Testing - Cat/Dog Voting App" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

switch ($Action) {
    "azure" {
        Write-Host "🔴 Scaling down Azure AKS deployment..." -ForegroundColor Yellow
        Write-Host "Run this command in a separate terminal with kubectl configured for Azure:" -ForegroundColor White
        Write-Host "kubectl scale deployment voting-app --replicas=0" -ForegroundColor White
        Write-Host ""
        Write-Host "⏳ Waiting 30 seconds for scaling to take effect..."
        Start-Sleep 30
        
        Write-Host "🧪 Testing endpoints after Azure scale-down:"
        Write-Host "Expected: Azure should fail, On-premises should work"
        Test-Endpoint $AzureEndpoint
        Test-Endpoint $OnPremEndpoint
    }
    
    "onprem" {
        Write-Host "🔴 Scaling down On-Premises deployment..." -ForegroundColor Yellow
        Write-Host "Run this command on your Ubuntu machine:" -ForegroundColor White
        Write-Host "kubectl scale deployment voting-app-onprem --replicas=0" -ForegroundColor White
        Write-Host ""
        Write-Host "⏳ Waiting 30 seconds for scaling to take effect..."
        Start-Sleep 30
        
        Write-Host "🧪 Testing endpoints after On-Premises scale-down:"
        Write-Host "Expected: On-premises should fail, Azure should work"
        Test-Endpoint $AzureEndpoint
        Test-Endpoint $OnPremEndpoint
    }
    
    "restore" {
        Write-Host "🔄 Restoring all deployments..." -ForegroundColor Green
        Write-Host "Run these commands to restore both environments:" -ForegroundColor White
        Write-Host ""
        Write-Host "For Azure (kubectl configured for Azure):" -ForegroundColor Yellow
        Write-Host "kubectl scale deployment voting-app --replicas=3" -ForegroundColor White
        Write-Host ""
        Write-Host "For On-Premises (on Ubuntu machine):" -ForegroundColor Yellow
        Write-Host "kubectl scale deployment voting-app-onprem --replicas=1" -ForegroundColor White
        Write-Host ""
        Write-Host "⏳ Waiting 60 seconds for pods to start..."
        Start-Sleep 60
        
        Write-Host "🧪 Testing endpoints after restoration:"
        Write-Host "Expected: Both should work"
        Test-Endpoint $AzureEndpoint
        Test-Endpoint $OnPremEndpoint
    }
}

Write-Host ""
Write-Host "📊 Current Status Summary:" -ForegroundColor Cyan
Write-Host "Azure AKS:      $AzureEndpoint"
Write-Host "On-Premises:    $OnPremEndpoint"
Write-Host ""
Write-Host "💡 Usage Examples:" -ForegroundColor Yellow
Write-Host ".\scripts\Test-Failover.ps1 -Action azure     # Test Azure failure"
Write-Host ".\scripts\Test-Failover.ps1 -Action onprem    # Test On-Prem failure"
Write-Host ".\scripts\Test-Failover.ps1 -Action restore   # Restore both environments"
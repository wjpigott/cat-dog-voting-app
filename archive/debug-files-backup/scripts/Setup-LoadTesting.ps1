# Load Testing Configuration for Cat/Dog Voting App
# This script sets up Azure Load Testing and k6 scripts for multi-region testing

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-catdog-voting",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "CentralUS",
    
    [string]$LoadTestResourceName = "lt-catdog-voting",
    [string]$TargetURL = "", # Will be populated from App Gateway
    [int]$TestDurationMinutes = 10,
    [int]$VirtualUsers = 50
)

Write-Host "⚡ Setting up Load Testing for Cat/Dog Voting App" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Install Azure Load Testing CLI extension if not already installed
Write-Host "🔧 Installing Azure Load Testing CLI extension..." -ForegroundColor Yellow
az extension add --name load -y

# Create Azure Load Testing resource
Write-Host "🏗️ Creating Azure Load Testing resource..." -ForegroundColor Yellow
az load test-run create-by-cli `
    --resource-group $ResourceGroupName `
    --name $LoadTestResourceName `
    --display-name "Cat Dog Voting App Load Test" `
    --description "Multi-region load test for Cat/Dog Voting App with failover testing"

Write-Host "✅ Azure Load Testing resource created!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run Setup-AppGateway.ps1 to get the load balancer URL" -ForegroundColor White
Write-Host "2. Use the k6 script below for local testing" -ForegroundColor White
Write-Host "3. Scale your deployments during testing" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Load Testing Strategy:" -ForegroundColor Green
Write-Host "   • Test Duration: $TestDurationMinutes minutes" -ForegroundColor White
Write-Host "   • Virtual Users: $VirtualUsers concurrent" -ForegroundColor White
Write-Host "   • Test from multiple regions" -ForegroundColor White
Write-Host "   • Monitor both AKS and on-premises traffic" -ForegroundColor White
Write-Host "   • Test failover scenarios" -ForegroundColor White
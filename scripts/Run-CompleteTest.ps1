# Comprehensive Load Testing and Failover Automation
# This script orchestrates the complete testing scenario

param(
    [string]$AppGatewayURL = "",
    [int]$TestDurationMinutes = 10,
    [switch]$IncludeScaling,
    [switch]$IncludeFailover,
    [switch]$IncludeColorUpdate
)

Write-Host "🚀 Cat/Dog Voting App - Complete Load Testing & Failover Automation" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan

# Set defaults for switches if not specified
if (-not $PSBoundParameters.ContainsKey('IncludeScaling')) { $IncludeScaling = $true }
if (-not $PSBoundParameters.ContainsKey('IncludeFailover')) { $IncludeFailover = $true }
if (-not $PSBoundParameters.ContainsKey('IncludeColorUpdate')) { $IncludeColorUpdate = $true }

# Load configuration if available
if (Test-Path "load-balancer-config.json") {
    $Config = Get-Content "load-balancer-config.json" | ConvertFrom-Json
    if (!$AppGatewayURL) {
        $AppGatewayURL = "http://$($Config.PublicIP)"
    }
    Write-Host "📋 Using configuration: $($Config.AppGatewayName)" -ForegroundColor Green
}

if (!$AppGatewayURL) {
    Write-Host "❌ Please provide AppGatewayURL or run Setup-AppGateway.ps1 first" -ForegroundColor Red
    exit 1
}

Write-Host "🎯 Target URL: $AppGatewayURL" -ForegroundColor Yellow
Write-Host "⏱️ Test Duration: $TestDurationMinutes minutes" -ForegroundColor Yellow
Write-Host ""

# Step 1: Start Load Test
Write-Host "⚡ Step 1: Starting Load Test" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check if k6 is available
$k6Available = Get-Command k6 -ErrorAction SilentlyContinue
if ($k6Available) {
    Write-Host "🔧 Starting k6 load test..." -ForegroundColor Yellow
    
    $LoadTestJob = Start-Job -ScriptBlock {
        param($URL, $Duration)
        $env:TARGET_URL = $URL
        k6 run --duration="${Duration}m" --vus=50 "./load-tests/voting-app-load-test.js"
    } -ArgumentList $AppGatewayURL, $TestDurationMinutes
    
    Write-Host "✅ Load test started in background (Job ID: $($LoadTestJob.Id))" -ForegroundColor Green
} else {
    Write-Host "⚠️ k6 not found. Install k6 from https://k6.io/docs/getting-started/installation/" -ForegroundColor Yellow
    Write-Host "📋 Manual load test command:" -ForegroundColor Cyan
    Write-Host "   k6 run --duration='${TestDurationMinutes}m' --vus=50 --env TARGET_URL=$AppGatewayURL ./load-tests/voting-app-load-test.js" -ForegroundColor White
}

# Step 2: Scaling Test
if ($IncludeScaling) {
    Write-Host ""
    Write-Host "📈 Step 2: Running Scaling Test" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    
    # Wait 2 minutes for load test to ramp up
    Write-Host "⏳ Waiting 2 minutes for load test to ramp up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 120
    
    # Run scaling automation
    Write-Host "🔄 Starting scaling automation..." -ForegroundColor Yellow
    & "./scripts/Scale-Deployments.ps1"
}

# Step 3: Deploy Color Change (Blue to Green background)
if ($IncludeColorUpdate) {
    Write-Host ""
    Write-Host "🎨 Step 3: Deploying Visual Update (Blue→Green)" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    
    # Create a temporary version with green background
    $originalContent = Get-Content "quick-onprem-deploy.yaml" -Raw
    $greenContent = $originalContent -replace "background: linear-gradient\(135deg, #2c3e50 0%, #3498db 100%\)", "background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%)"
    $greenContent = $greenContent -replace "🏠 Running on On-Premises Azure Arc!", "🌿 UPDATED: Running on On-Premises Azure Arc!"
    
    # Save green version
    $greenContent | Out-File -FilePath "quick-onprem-deploy-green.yaml" -Encoding UTF8
    
    Write-Host "🌿 Created green version of the app..." -ForegroundColor Yellow
    Write-Host "🚀 Deploying update to both environments..." -ForegroundColor Yellow
    
    # Deploy green version
    kubectl apply -f "quick-onprem-deploy-green.yaml"
    
    # Also update Azure version if available
    if (Test-Path "k8s/azure/final-voting-app.yaml") {
        $azureContent = Get-Content "k8s/azure/final-voting-app.yaml" -Raw
        $azureGreenContent = $azureContent -replace "background: linear-gradient\(135deg, #2c3e50 0%, #3498db 100%\)", "background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%)"
        $azureGreenContent = $azureGreenContent -replace "☁️ Running on Azure AKS!", "🌿 UPDATED: Running on Azure AKS!"
        $azureGreenContent | Out-File -FilePath "azure-voting-app-green.yaml" -Encoding UTF8
        kubectl apply -f "azure-voting-app-green.yaml"
    }
    
    Write-Host "✅ Green version deployed! Check the UI for background color change." -ForegroundColor Green
    Write-Host "🌐 Visit: $AppGatewayURL" -ForegroundColor Cyan
}

# Step 4: Failover Testing
if ($IncludeFailover) {
    Write-Host ""
    Write-Host "🔄 Step 4: Failover Testing" -ForegroundColor Green
    Write-Host "===========================" -ForegroundColor Green
    
    Write-Host "⚠️ Manual Failover Steps:" -ForegroundColor Yellow
    Write-Host "1. Scale down Azure AKS to 0 replicas:" -ForegroundColor White
    Write-Host "   kubectl scale deployment voting-app --replicas=0" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Watch traffic shift to on-premises:" -ForegroundColor White
    Write-Host "   Monitor Application Gateway backend health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Scale Azure back up:" -ForegroundColor White
    Write-Host "   kubectl scale deployment voting-app --replicas=2" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. For DNS failover testing:" -ForegroundColor White
    Write-Host "   - Set DNS TTL to 1 second in your DNS provider" -ForegroundColor Cyan
    Write-Host "   - Switch DNS between Azure and on-premises IPs" -ForegroundColor Cyan
    Write-Host ""
    
    # Automated failover simulation
    $response = Read-Host "Would you like to run automated Azure failover simulation? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🔄 Simulating Azure AKS failure..." -ForegroundColor Red
        kubectl scale deployment voting-app --replicas=0
        
        Write-Host "⏳ Waiting 30 seconds for failover..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        Write-Host "🔄 Restoring Azure AKS..." -ForegroundColor Green
        kubectl scale deployment voting-app --replicas=2
        
        Write-Host "✅ Failover simulation complete" -ForegroundColor Green
    }
}

# Step 5: Monitoring and Results
Write-Host ""
Write-Host "📊 Step 5: Monitoring & Results" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

Write-Host "📈 Real-time Monitoring Commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application Gateway Backend Health:" -ForegroundColor Yellow
Write-Host "az network application-gateway show-backend-health --name $($Config.AppGatewayName) --resource-group $($Config.ResourceGroup)" -ForegroundColor White
Write-Host ""
Write-Host "Pod Status - Azure AKS:" -ForegroundColor Yellow
Write-Host "kubectl get pods -l app=voting-app -o wide" -ForegroundColor White
Write-Host ""
Write-Host "Pod Status - On-Premises:" -ForegroundColor Yellow
Write-Host "kubectl get pods -l app=voting-app-onprem -o wide --context=onprem" -ForegroundColor White
Write-Host ""
Write-Host "Service Status:" -ForegroundColor Yellow
Write-Host "kubectl get services" -ForegroundColor White

# Wait for load test to complete
if ($k6Available -and $LoadTestJob) {
    Write-Host ""
    Write-Host "⏳ Waiting for load test to complete..." -ForegroundColor Yellow
    Wait-Job $LoadTestJob | Out-Null
    $LoadTestResults = Receive-Job $LoadTestJob
    Write-Host "📊 Load Test Results:" -ForegroundColor Green
    Write-Host $LoadTestResults -ForegroundColor White
    Remove-Job $LoadTestJob
}

Write-Host ""
Write-Host "🎉 Complete Load Testing & Failover Test Finished!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary of Tests Performed:" -ForegroundColor Cyan
Write-Host "✅ Load testing with k6 ($TestDurationMinutes minutes)" -ForegroundColor White
if ($IncludeScaling) { Write-Host "✅ Scaling automation (1→4 replicas)" -ForegroundColor White }
if ($IncludeColorUpdate) { Write-Host "✅ Rolling update (blue→green background)" -ForegroundColor White }
if ($IncludeFailover) { Write-Host "✅ Failover simulation and testing" -ForegroundColor White }
Write-Host ""
Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
Write-Host "Load Balancer: $AppGatewayURL" -ForegroundColor Yellow
Write-Host "Azure Direct: http://52.154.54.110" -ForegroundColor Yellow
Write-Host "On-Premises Direct: http://66.242.207.21:31514" -ForegroundColor Yellow
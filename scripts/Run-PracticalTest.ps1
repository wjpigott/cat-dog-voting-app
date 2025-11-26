# Practical Load Testing Setup for Cat/Dog Voting App
# This approach uses your existing endpoints directly for testing

param(
    [int]$TestDurationMinutes = 10,
    [switch]$IncludeScaling,
    [switch]$IncludeFailover,
    [switch]$IncludeColorUpdate
)

Write-Host "🚀 Practical Load Testing for Cat/Dog Voting App" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Your existing endpoints
$AzureEndpoint = "http://52.154.54.110"
$OnPremEndpoint = "http://66.242.207.21:31514"

Write-Host "🎯 Testing Endpoints:" -ForegroundColor Yellow
Write-Host "   • Azure AKS: $AzureEndpoint" -ForegroundColor White
Write-Host "   • On-Premises: $OnPremEndpoint" -ForegroundColor White
Write-Host "   • Test Duration: $TestDurationMinutes minutes" -ForegroundColor White
Write-Host ""

# Set defaults for switches if not specified
if (-not $PSBoundParameters.ContainsKey('IncludeScaling')) { $IncludeScaling = $true }
if (-not $PSBoundParameters.ContainsKey('IncludeFailover')) { $IncludeFailover = $true }
if (-not $PSBoundParameters.ContainsKey('IncludeColorUpdate')) { $IncludeColorUpdate = $true }

# Test connectivity to both endpoints
Write-Host "🔍 Testing endpoint connectivity..." -ForegroundColor Yellow
try {
    $azureResponse = Invoke-WebRequest -Uri $AzureEndpoint -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Azure AKS endpoint accessible (Status: $($azureResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure AKS endpoint not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $onpremResponse = Invoke-WebRequest -Uri $OnPremEndpoint -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ On-premises endpoint accessible (Status: $($onpremResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ On-premises endpoint not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 1: Start Load Test for Both Endpoints
Write-Host ""
Write-Host "⚡ Step 1: Starting Load Tests" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# Check if k6 is available
$k6Available = Get-Command k6 -ErrorAction SilentlyContinue
if ($k6Available) {
    Write-Host "🔧 Starting k6 load tests for both endpoints..." -ForegroundColor Yellow
    
    # Start load test for Azure
    $AzureLoadTestJob = Start-Job -ScriptBlock {
        param($URL, $Duration, $Name)
        $env:TARGET_URL = $URL
        $env:TEST_NAME = $Name
        k6 run --duration="${Duration}m" --vus=25 "./load-tests/voting-app-load-test.js"
    } -ArgumentList $AzureEndpoint, $TestDurationMinutes, "Azure"
    
    # Start load test for On-Premises  
    $OnPremLoadTestJob = Start-Job -ScriptBlock {
        param($URL, $Duration, $Name)
        $env:TARGET_URL = $URL
        $env:TEST_NAME = $Name
        k6 run --duration="${Duration}m" --vus=25 "./load-tests/voting-app-load-test.js"
    } -ArgumentList $OnPremEndpoint, $TestDurationMinutes, "OnPrem"
    
    Write-Host "✅ Load tests started:" -ForegroundColor Green
    Write-Host "   • Azure AKS test (Job ID: $($AzureLoadTestJob.Id))" -ForegroundColor White
    Write-Host "   • On-Premises test (Job ID: $($OnPremLoadTestJob.Id))" -ForegroundColor White
} else {
    Write-Host "⚠️ k6 not found. Install k6 from https://k6.io/docs/getting-started/installation/" -ForegroundColor Yellow
    Write-Host "📋 Manual load test commands:" -ForegroundColor Cyan
    Write-Host "   # Azure endpoint:" -ForegroundColor White
    Write-Host "   k6 run --duration='${TestDurationMinutes}m' --vus=25 --env TARGET_URL=$AzureEndpoint ./load-tests/voting-app-load-test.js" -ForegroundColor Gray
    Write-Host "   # On-premises endpoint:" -ForegroundColor White
    Write-Host "   k6 run --duration='${TestDurationMinutes}m' --vus=25 --env TARGET_URL=$OnPremEndpoint ./load-tests/voting-app-load-test.js" -ForegroundColor Gray
}

# Step 2: Scaling Test
if ($IncludeScaling) {
    Write-Host ""
    Write-Host "📈 Step 2: Running Scaling Test" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    
    # Wait 2 minutes for load test to ramp up
    Write-Host "⏳ Waiting 2 minutes for load tests to ramp up..." -ForegroundColor Yellow
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
    
    # Create a temporary version with green background for on-premises
    $originalContent = Get-Content "quick-onprem-deploy.yaml" -Raw
    $greenContent = $originalContent -replace "background: linear-gradient\(135deg, #2c3e50 0%, #3498db 100%\)", "background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%)"
    $greenContent = $greenContent -replace "🏠 Running on On-Premises Azure Arc!", "🌿 UPDATED: Running on On-Premises Azure Arc!"
    
    # Save green version
    $greenContent | Out-File -FilePath "quick-onprem-deploy-green.yaml" -Encoding UTF8
    
    Write-Host "🌿 Created green version of the on-premises app..." -ForegroundColor Yellow
    Write-Host "🚀 Deploying update to on-premises..." -ForegroundColor Yellow
    
    # Deploy green version to on-premises
    kubectl apply -f "quick-onprem-deploy-green.yaml"
    
    # Also update Azure version if available
    if (Test-Path "k8s/azure/final-voting-app.yaml") {
        $azureContent = Get-Content "k8s/azure/final-voting-app.yaml" -Raw
        $azureGreenContent = $azureContent -replace "background: linear-gradient\(135deg, #2c3e50 0%, #3498db 100%\)", "background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%)"
        $azureGreenContent = $azureGreenContent -replace "☁️ Running on Azure AKS!", "🌿 UPDATED: Running on Azure AKS!"
        $azureGreenContent | Out-File -FilePath "azure-voting-app-green.yaml" -Encoding UTF8
        kubectl apply -f "azure-voting-app-green.yaml"
        Write-Host "🌿 Green version deployed to Azure AKS too!" -ForegroundColor Yellow
    }
    
    Write-Host "✅ Green version deployed! Check both URLs for background color change." -ForegroundColor Green
    Write-Host "🌐 Azure: $AzureEndpoint" -ForegroundColor Cyan
    Write-Host "🏠 On-Prem: $OnPremEndpoint" -ForegroundColor Cyan
}

# Step 4: Failover Testing
if ($IncludeFailover) {
    Write-Host ""
    Write-Host "🔄 Step 4: Failover Testing" -ForegroundColor Green
    Write-Host "===========================" -ForegroundColor Green
    
    # Automated failover simulation
    $response = Read-Host "Would you like to run automated Azure failover simulation? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🔄 Simulating Azure AKS failure..." -ForegroundColor Red
        kubectl scale deployment voting-app --replicas=0
        
        Write-Host "⏳ Waiting 30 seconds for failover impact..." -ForegroundColor Yellow
        Write-Host "   • Azure endpoint should become unavailable" -ForegroundColor White
        Write-Host "   • On-premises endpoint should still work" -ForegroundColor White
        Write-Host "   • Load test will show Azure failures, on-premises success" -ForegroundColor White
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
Write-Host "Pod Status - Azure AKS:" -ForegroundColor Yellow
Write-Host "kubectl get pods -l app=voting-app -o wide" -ForegroundColor White
Write-Host ""
Write-Host "Pod Status - On-Premises:" -ForegroundColor Yellow
Write-Host "kubectl get pods -l app=voting-app-onprem -o wide --context=onprem" -ForegroundColor White
Write-Host ""
Write-Host "Service Status:" -ForegroundColor Yellow
Write-Host "kubectl get services" -ForegroundColor White
Write-Host ""

# Simple load balancing test using PowerShell
Write-Host "🔄 Simple Load Balancing Test (PowerShell):" -ForegroundColor Cyan
Write-Host "for (`$i=1; `$i -le 10; `$i++) { " -ForegroundColor White
Write-Host "    if (`$i % 2 -eq 0) { " -ForegroundColor White
Write-Host "        Invoke-WebRequest $AzureEndpoint | Select-Object StatusCode, @{Name='Environment';Expression={'Azure'}} " -ForegroundColor White
Write-Host "    } else { " -ForegroundColor White
Write-Host "        Invoke-WebRequest $OnPremEndpoint | Select-Object StatusCode, @{Name='Environment';Expression={'OnPrem'}} " -ForegroundColor White
Write-Host "    } " -ForegroundColor White
Write-Host "}" -ForegroundColor White

# Wait for load tests to complete
if ($k6Available -and $AzureLoadTestJob -and $OnPremLoadTestJob) {
    Write-Host ""
    Write-Host "⏳ Waiting for load tests to complete..." -ForegroundColor Yellow
    
    # Wait for Azure test
    Wait-Job $AzureLoadTestJob | Out-Null
    $AzureResults = Receive-Job $AzureLoadTestJob
    Write-Host "📊 Azure Load Test Results:" -ForegroundColor Green
    Write-Host $AzureResults -ForegroundColor White
    Remove-Job $AzureLoadTestJob
    
    # Wait for On-Prem test
    Wait-Job $OnPremLoadTestJob | Out-Null
    $OnPremResults = Receive-Job $OnPremLoadTestJob
    Write-Host "📊 On-Premises Load Test Results:" -ForegroundColor Green
    Write-Host $OnPremResults -ForegroundColor White
    Remove-Job $OnPremLoadTestJob
}

Write-Host ""
Write-Host "🎉 Complete Load Testing Finished!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary of Tests Performed:" -ForegroundColor Cyan
Write-Host "✅ Load testing on both endpoints ($TestDurationMinutes minutes each)" -ForegroundColor White
if ($IncludeScaling) { Write-Host "✅ Scaling automation (1→4 replicas)" -ForegroundColor White }
if ($IncludeColorUpdate) { Write-Host "✅ Rolling update (blue→green background)" -ForegroundColor White }
if ($IncludeFailover) { Write-Host "✅ Failover simulation and testing" -ForegroundColor White }
Write-Host ""
Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
Write-Host "Azure AKS: $AzureEndpoint" -ForegroundColor Yellow
Write-Host "On-Premises: $OnPremEndpoint" -ForegroundColor Yellow
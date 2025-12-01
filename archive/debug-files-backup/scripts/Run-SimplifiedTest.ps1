# Simplified Load Testing for Cat/Dog Voting App
# This version works without k6 or kubectl dependencies

param(
    [int]$TestDurationMinutes = 5,
    [int]$ConcurrentUsers = 10,
    [switch]$TestBothEndpoints
)

Write-Host "🚀 Simplified Load Testing for Cat/Dog Voting App" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Your endpoints
$AzureEndpoint = "http://52.154.54.110"
$OnPremEndpoint = "http://66.242.207.21:31514"

Write-Host "🎯 Testing Configuration:" -ForegroundColor Yellow
Write-Host "   • Test Duration: $TestDurationMinutes minutes" -ForegroundColor White
Write-Host "   • Concurrent Users: $ConcurrentUsers" -ForegroundColor White
Write-Host "   • Azure AKS: $AzureEndpoint" -ForegroundColor White
Write-Host "   • On-Premises: $OnPremEndpoint" -ForegroundColor White
Write-Host ""

# Test endpoint connectivity first
Write-Host "🔍 Step 1: Testing Endpoint Connectivity" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$azureWorking = $false
$onpremWorking = $false

Write-Host "Testing Azure AKS endpoint..." -ForegroundColor Yellow
try {
    $azureTest = Invoke-WebRequest -Uri $AzureEndpoint -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ Azure AKS accessible (Status: $($azureTest.StatusCode))" -ForegroundColor Green
    $azureWorking = $true
} catch {
    Write-Host "❌ Azure AKS not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Testing On-Premises endpoint..." -ForegroundColor Yellow
try {
    $onpremTest = Invoke-WebRequest -Uri $OnPremEndpoint -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ On-Premises accessible (Status: $($onpremTest.StatusCode))" -ForegroundColor Green
    $onpremWorking = $true
} catch {
    Write-Host "❌ On-Premises not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

if (-not $azureWorking -and -not $onpremWorking) {
    Write-Host "❌ Both endpoints are unavailable. Please check your deployments." -ForegroundColor Red
    return
}

# Step 2: PowerShell-based Load Testing
Write-Host ""
Write-Host "⚡ Step 2: PowerShell Load Testing" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

$testEndpoints = @()
if ($azureWorking) { $testEndpoints += @{Name="Azure"; URL=$AzureEndpoint} }
if ($onpremWorking) { $testEndpoints += @{Name="OnPrem"; URL=$OnPremEndpoint} }

Write-Host "🚀 Starting load test with $ConcurrentUsers concurrent users for $TestDurationMinutes minutes..." -ForegroundColor Yellow
Write-Host ""

# Create performance counters
$results = @{}
$testEndpoints | ForEach-Object { 
    $results[$_.Name] = @{
        SuccessCount = 0
        ErrorCount = 0
        TotalResponseTime = 0
        MaxResponseTime = 0
        MinResponseTime = [int]::MaxValue
    }
}

# Calculate test parameters
$testDurationSeconds = $TestDurationMinutes * 60
$requestsPerUser = [math]::Max(1, $testDurationSeconds / 10)  # One request every 10 seconds per user
$totalRequests = $ConcurrentUsers * $requestsPerUser

Write-Host "📊 Test Parameters:" -ForegroundColor Cyan
Write-Host "   • Total Requests: $totalRequests" -ForegroundColor White
Write-Host "   • Requests per User: $requestsPerUser" -ForegroundColor White
Write-Host "   • Test Duration: $testDurationSeconds seconds" -ForegroundColor White
Write-Host ""

# Run load test using PowerShell jobs
$jobs = @()
$startTime = Get-Date

for ($user = 1; $user -le $ConcurrentUsers; $user++) {
    $job = Start-Job -ScriptBlock {
        param($TestEndpoints, $RequestsPerUser, $UserNumber, $TestDurationSeconds)
        
        $endTime = (Get-Date).AddSeconds($TestDurationSeconds)
        $userResults = @{}
        
        # Initialize results for this user
        $TestEndpoints | ForEach-Object {
            $userResults[$_.Name] = @{
                SuccessCount = 0
                ErrorCount = 0
                ResponseTimes = @()
            }
        }
        
        $requestCount = 0
        while ((Get-Date) -lt $endTime -and $requestCount -lt $RequestsPerUser) {
            # Round-robin between endpoints
            $endpoint = $TestEndpoints[$requestCount % $TestEndpoints.Count]
            
            try {
                $startRequest = Get-Date
                $response = Invoke-WebRequest -Uri $endpoint.URL -TimeoutSec 10 -UseBasicParsing
                $responseTime = ((Get-Date) - $startRequest).TotalMilliseconds
                
                $userResults[$endpoint.Name].SuccessCount++
                $userResults[$endpoint.Name].ResponseTimes += $responseTime
                
            } catch {
                $userResults[$endpoint.Name].ErrorCount++
            }
            
            $requestCount++
            Start-Sleep -Milliseconds 100  # Brief pause between requests
        }
        
        return $userResults
    } -ArgumentList $testEndpoints, $requestsPerUser, $user, $testDurationSeconds
    
    $jobs += $job
    Write-Host "👤 Started user $user" -ForegroundColor Gray
    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host "⏳ Running load test... (this will take $TestDurationMinutes minutes)" -ForegroundColor Yellow

# Monitor progress
$progressInterval = [math]::Max(1, $testDurationSeconds / 10)
for ($i = 0; $i -lt $testDurationSeconds; $i += $progressInterval) {
    $remaining = $testDurationSeconds - $i
    Write-Host "   ⏰ $remaining seconds remaining..." -ForegroundColor Gray
    Start-Sleep -Seconds $progressInterval
}

# Wait for all jobs to complete
Write-Host "🔄 Collecting results..." -ForegroundColor Yellow
$allResults = @{}
$testEndpoints | ForEach-Object { 
    $allResults[$_.Name] = @{
        SuccessCount = 0
        ErrorCount = 0
        ResponseTimes = @()
    }
}

$jobs | ForEach-Object {
    $jobResult = Receive-Job $_
    Remove-Job $_
    
    # Aggregate results
    foreach ($endpointName in $jobResult.Keys) {
        $allResults[$endpointName].SuccessCount += $jobResult[$endpointName].SuccessCount
        $allResults[$endpointName].ErrorCount += $jobResult[$endpointName].ErrorCount
        $allResults[$endpointName].ResponseTimes += $jobResult[$endpointName].ResponseTimes
    }
}

# Calculate and display results
$endTime = Get-Date
$actualDuration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "🎉 Load Test Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host "📊 Test Summary:" -ForegroundColor Cyan
Write-Host "   • Actual Duration: $([math]::Round($actualDuration, 1)) seconds" -ForegroundColor White
Write-Host "   • Concurrent Users: $ConcurrentUsers" -ForegroundColor White
Write-Host ""

foreach ($endpointName in $allResults.Keys) {
    $result = $allResults[$endpointName]
    $totalRequests = $result.SuccessCount + $result.ErrorCount
    $successRate = if ($totalRequests -gt 0) { [math]::Round(($result.SuccessCount / $totalRequests) * 100, 2) } else { 0 }
    
    if ($result.ResponseTimes.Count -gt 0) {
        $avgResponseTime = [math]::Round(($result.ResponseTimes | Measure-Object -Average).Average, 2)
        $minResponseTime = [math]::Round(($result.ResponseTimes | Measure-Object -Minimum).Minimum, 2)
        $maxResponseTime = [math]::Round(($result.ResponseTimes | Measure-Object -Maximum).Maximum, 2)
    } else {
        $avgResponseTime = $minResponseTime = $maxResponseTime = 0
    }
    
    Write-Host "🎯 $endpointName Endpoint Results:" -ForegroundColor Yellow
    Write-Host "   • Total Requests: $totalRequests" -ForegroundColor White
    Write-Host "   • Successful: $($result.SuccessCount)" -ForegroundColor Green
    Write-Host "   • Failed: $($result.ErrorCount)" -ForegroundColor $(if ($result.ErrorCount -gt 0) { "Red" } else { "White" })
    Write-Host "   • Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
    Write-Host "   • Avg Response Time: $avgResponseTime ms" -ForegroundColor White
    Write-Host "   • Min Response Time: $minResponseTime ms" -ForegroundColor White
    Write-Host "   • Max Response Time: $maxResponseTime ms" -ForegroundColor White
    Write-Host ""
}

# Step 3: Manual Failover Test
Write-Host "🔄 Step 3: Manual Failover Testing" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host "📋 Manual Commands for Failover Testing:" -ForegroundColor Cyan
Write-Host ""

if ($azureWorking) {
    Write-Host "🔴 To simulate Azure failure:" -ForegroundColor Red
    Write-Host "   # Scale down Azure deployment (if kubectl available):" -ForegroundColor White
    Write-Host "   kubectl scale deployment voting-app --replicas=0" -ForegroundColor Gray
    Write-Host ""
}

if ($onpremWorking) {
    Write-Host "🔴 To simulate On-Premises failure:" -ForegroundColor Red
    Write-Host "   # Scale down on-premises deployment:" -ForegroundColor White
    Write-Host "   kubectl scale deployment voting-app-onprem --replicas=0 --context=onprem" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "🔧 DNS Load Balancing Setup:" -ForegroundColor Cyan
Write-Host "   1. Set up DNS round-robin with 1-second TTL" -ForegroundColor White
Write-Host "   2. Point your domain to both IPs:" -ForegroundColor White
if ($azureWorking) { Write-Host "      - 52.154.54.110 (Azure)" -ForegroundColor Cyan }
if ($onpremWorking) { Write-Host "      - 66.242.207.21 (On-Premises)" -ForegroundColor Cyan }
Write-Host ""

Write-Host "🎯 Recommendation for Full Testing:" -ForegroundColor Green
Write-Host "   1. Install k6: winget install k6" -ForegroundColor White
Write-Host "   2. Install kubectl for Kubernetes management" -ForegroundColor White
Write-Host "   3. Set up Azure Traffic Manager for production load balancing" -ForegroundColor White

Write-Host ""
Write-Host "✅ Simplified Load Testing Complete!" -ForegroundColor Green
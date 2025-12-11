# Fix Azure CLI and Deploy Traffic Manager
# This script fixes Azure CLI permission issues and deploys Traffic Manager

param(
    [switch]$FixCLI,
    [switch]$Deploy,
    [string]$ResourceGroup = "rg-cat-dog-voting",
    [string]$ProfileName = "voting-app-tm-$(Get-Random -Minimum 1000 -Maximum 9999)"
)

# Colors
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow" 
$Cyan = "Cyan"
$Magenta = "Magenta"
$Gray = "Gray"

Write-Host "🔧 AZURE CLI FIXER & TRAFFIC MANAGER DEPLOYER" -ForegroundColor $Magenta
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $Gray

# Function to test if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to fix Azure CLI extensions
function Fix-AzureCLI {
    Write-Host "🔧 Fixing Azure CLI Permission Issues..." -ForegroundColor $Cyan
    
    if (-not (Test-Administrator)) {
        Write-Host "⚠️ Administrative privileges required to fix CLI" -ForegroundColor $Yellow
        Write-Host "Attempting to restart as administrator..." -ForegroundColor $Gray
        
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process PowerShell -ArgumentList "-File `"$scriptPath`" -FixCLI" -Verb RunAs -Wait
        return
    }
    
    Write-Host "✅ Running as Administrator" -ForegroundColor $Green
    
    # Stop any Azure CLI processes
    Get-Process -Name "az" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Remove problematic extensions directory
    $extensionsPath = "$env:USERPROFILE\.azure\cliextensions"
    if (Test-Path $extensionsPath) {
        Write-Host "🗑️ Removing problematic extensions..." -ForegroundColor $Yellow
        try {
            Remove-Item -Path $extensionsPath -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Extensions removed" -ForegroundColor $Green
        }
        catch {
            Write-Host "⚠️ Could not remove all extensions: $($_.Exception.Message)" -ForegroundColor $Yellow
        }
    }
    
    # Recreate extensions directory with proper permissions
    Write-Host "📁 Creating new extensions directory..." -ForegroundColor $Cyan
    New-Item -Path $extensionsPath -ItemType Directory -Force | Out-Null
    
    # Set proper permissions
    $acl = Get-Acl $extensionsPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $extensionsPath -AclObject $acl
    
    Write-Host "✅ Azure CLI permissions fixed!" -ForegroundColor $Green
    Write-Host "Now run: .\scripts\deploy-traffic-manager-fixed.ps1 -Deploy" -ForegroundColor $Cyan
}

# Function to test Azure CLI
function Test-AzureCLI {
    Write-Host "🔍 Testing Azure CLI..." -ForegroundColor $Cyan
    try {
        $null = az --version 2>$null
        Write-Host "✅ Azure CLI is working" -ForegroundColor $Green
        return $true
    }
    catch {
        Write-Host "❌ Azure CLI has issues: $($_.Exception.Message)" -ForegroundColor $Red
        return $false
    }
}

# Function to deploy Traffic Manager
function Deploy-TrafficManager {
    Write-Host "🚀 Deploying Traffic Manager..." -ForegroundColor $Green
    
    # Test endpoints first
    Write-Host "🔍 Testing endpoints..." -ForegroundColor $Cyan
    
    $azureHealthy = $false
    $onpremHealthy = $false
    
    try {
        $response = Invoke-WebRequest -Uri "http://52.154.54.110" -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ Azure AKS: Healthy (Status: $($response.StatusCode))" -ForegroundColor $Green
        $azureHealthy = $true
    }
    catch {
        Write-Host "⚠️ Azure AKS: Not responding" -ForegroundColor $Yellow
    }
    
    try {
        $response = Invoke-WebRequest -Uri "http://66.242.207.21:31514" -Method HEAD -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ OnPrem K3s: Healthy (Status: $($response.StatusCode))" -ForegroundColor $Green
        $onpremHealthy = $true
    }
    catch {
        Write-Host "⚠️ OnPrem K3s: Not responding" -ForegroundColor $Yellow
    }
    
    if (-not $azureHealthy -and -not $onpremHealthy) {
        Write-Host "❌ Both endpoints are down. Cannot deploy Traffic Manager." -ForegroundColor $Red
        return
    }
    
    # Test Azure CLI
    if (-not (Test-AzureCLI)) {
        Write-Host "❌ Azure CLI is not working. Run with -FixCLI first." -ForegroundColor $Red
        return
    }
    
    # Check login
    Write-Host "🔐 Checking Azure login..." -ForegroundColor $Cyan
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if (-not $account) {
            throw "Not logged in"
        }
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor $Green
    }
    catch {
        Write-Host "🔑 Please login to Azure..." -ForegroundColor $Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Azure login failed" -ForegroundColor $Red
            return
        }
    }
    
    # Create resource group if needed
    Write-Host "📦 Ensuring resource group exists..." -ForegroundColor $Cyan
    az group create --name $ResourceGroup --location "centralus" --output none
    
    # Deploy Traffic Manager using ARM template
    Write-Host "🌐 Deploying Traffic Manager profile: $ProfileName" -ForegroundColor $Green
    
    $deploymentResult = az deployment group create `
        --resource-group $ResourceGroup `
        --template-file "azure-traffic-manager.json" `
        --parameters profileName=$ProfileName azureEndpoint="52.154.54.110" onpremEndpoint="66.242.207.21" onpremPort=31514 `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Traffic Manager deployed successfully!" -ForegroundColor $Green
        $fqdn = $deploymentResult.properties.outputs.trafficManagerFqdn.value
        $url = $deploymentResult.properties.outputs.trafficManagerUrl.value
        
        Write-Host "`n🌐 YOUR TRAFFIC MANAGER URL:" -ForegroundColor $Magenta
        Write-Host "$url" -ForegroundColor $Yellow
        
        Write-Host "`n🧪 Test failover with:" -ForegroundColor $Cyan
        Write-Host ".\scripts\test-failover-tm.sh `"$url`"" -ForegroundColor $Gray
        
        # Start monitoring
        Write-Host "`n🔍 Starting monitoring..." -ForegroundColor $Cyan
        Start-Process PowerShell -ArgumentList "-File .\scripts\monitor-traffic-manager.ps1 -TrafficManagerUrl `"$url`""
    }
    else {
        Write-Host "❌ Deployment failed!" -ForegroundColor $Red
    }
}

# Main execution
if ($FixCLI) {
    Fix-AzureCLI
}
elseif ($Deploy) {
    Deploy-TrafficManager
}
else {
    Write-Host "📋 Usage:" -ForegroundColor $Cyan
    Write-Host "  Fix Azure CLI: .\scripts\deploy-traffic-manager-fixed.ps1 -FixCLI" -ForegroundColor $Gray
    Write-Host "  Deploy TM:     .\scripts\deploy-traffic-manager-fixed.ps1 -Deploy" -ForegroundColor $Gray
    Write-Host ""
    Write-Host "🔧 Recommended: Run both steps in order" -ForegroundColor $Yellow
    Write-Host "1. .\scripts\deploy-traffic-manager-fixed.ps1 -FixCLI" -ForegroundColor $White
    Write-Host "2. .\scripts\deploy-traffic-manager-fixed.ps1 -Deploy" -ForegroundColor $White
}
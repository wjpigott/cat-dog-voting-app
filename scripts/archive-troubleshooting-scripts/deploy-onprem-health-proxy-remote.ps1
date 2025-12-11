# Remote Deploy OnPrem Health Proxy via SSH
# This script uses SSH to deploy to your Linux K3s machine

param(
    [Parameter(Mandatory=$true)]
    [string]$LinuxHost = "66.242.207.21",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "ubuntu",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHKey = ""
)

Write-Host "🚀 REMOTE DEPLOYING ONPREM HEALTH PROXY" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🖥️  Target: $Username@$LinuxHost" -ForegroundColor Yellow

# Check if SSH is available
if (!(Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ SSH not found. Please install OpenSSH or use WSL" -ForegroundColor Red
    exit 1
}

# Build SSH command
$sshCmd = "ssh"
if ($SSHKey) {
    $sshCmd += " -i `"$SSHKey`""
}
$sshCmd += " $Username@$LinuxHost"

Write-Host "🔄 Testing SSH connection..." -ForegroundColor Yellow
$testConnection = Invoke-Expression "$sshCmd 'echo Connection successful'" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ SSH connection failed:" -ForegroundColor Red
    Write-Host $testConnection -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    Write-Host "💡 Try one of these alternatives:" -ForegroundColor Cyan
    Write-Host "1. Set up SSH key authentication" -ForegroundColor Yellow
    Write-Host "2. Manually copy and run the Linux script on $LinuxHost" -ForegroundColor Yellow
    Write-Host "3. Use the manual instructions below" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ SSH connection successful" -ForegroundColor Green

# Copy the health proxy YAML content to remote machine
Write-Host "📤 Copying health proxy configuration..." -ForegroundColor Yellow
$yamlContent = Get-Content ".\traffic-manager-health-proxy.yaml" -Raw
$yamlContent = $yamlContent -replace "'", "'\"'\"'"  # Escape single quotes for bash

$copyCommand = @"
$sshCmd 'cat > traffic-manager-health-proxy.yaml << '\''EOF'\''
$yamlContent
EOF'
"@

Invoke-Expression $copyCommand
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to copy YAML file" -ForegroundColor Red
    exit 1
}

# Copy and run the deployment script
Write-Host "📤 Copying and running deployment script..." -ForegroundColor Yellow
$scriptContent = Get-Content ".\scripts\deploy-onprem-health-proxy-linux.sh" -Raw
$scriptContent = $scriptContent -replace "'", "'\"'\"'"  # Escape single quotes for bash

$deployCommand = @"
$sshCmd 'cat > deploy-health-proxy.sh << '\''EOF'\''
$scriptContent
EOF
chmod +x deploy-health-proxy.sh
./deploy-health-proxy.sh'
"@

Write-Host "🚀 Running deployment on remote machine..." -ForegroundColor Yellow
Invoke-Expression $deployCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "" -ForegroundColor White
    Write-Host "🎯 REMOTE DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
    Write-Host "════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ Health proxy deployed to $LinuxHost" -ForegroundColor Green
    Write-Host "🔄 Traffic Manager will detect OnPrem health in 2-3 minutes" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "🧪 Test with: .\scripts\test-failover-analysis.ps1" -ForegroundColor Cyan
} else {
    Write-Host "❌ Remote deployment failed" -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    Write-Host "💡 Manual alternative: Copy the Linux script to $LinuxHost and run it there" -ForegroundColor Yellow
}
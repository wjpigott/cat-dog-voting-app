# PowerShell GitHub Deployment Script for Symmetric Voting App
# Run this script to commit all files to GitHub and deploy from URLs

param(
    [Parameter(HelpMessage="GitHub username")]
    [string]$GitHubUser = "",
    
    [Parameter(HelpMessage="GitHub repository name")]  
    [string]$GitHubRepo = "cat-dog-voting-app",
    
    [Parameter(HelpMessage="Skip git operations and just generate deployment commands")]
    [switch]$SkipGit
)

Write-Host "🚀 Symmetric Voting App - GitHub Deployment Manager" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

# Check if we have git
$gitAvailable = $false
try {
    git --version 2>&1 | Out-Null
    $gitAvailable = $true
    Write-Host "✅ Git is available" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Git not found in PATH - will provide manual instructions" -ForegroundColor Yellow
}

# Files to commit
$filesToCommit = @(
    "cross-environment-voting-azure.yaml",
    "cross-environment-voting-onprem.yaml", 
    "quick-fix-onprem-azure-api.yaml",
    "quick-onprem-deploy-green.yaml",
    "deploy-fixed-onprem.sh",
    "deploy-from-github.sh", 
    "commit-symmetric-voting.sh",
    "SYMMETRIC_VOTING_COMMIT_GUIDE.md",
    "GITHUB_DEPLOYMENT_GUIDE.md"
)

Write-Host "`n📁 Files ready for commit:" -ForegroundColor Cyan
foreach ($file in $filesToCommit) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file (missing)" -ForegroundColor Red
    }
}

if ($gitAvailable -and -not $SkipGit) {
    Write-Host "`n🔧 Performing Git Operations..." -ForegroundColor Yellow
    
    # Add files
    foreach ($file in $filesToCommit) {
        if (Test-Path $file) {
            git add $file
            Write-Host "  Added: $file" -ForegroundColor Green
        }
    }
    
    # Commit
    $commitMessage = @"
feat: Symmetric cross-environment voting with accurate Azure API integration

- Enhanced Azure UI with purple gradient and cross-environment analytics
- Symmetric on-premises app with Azure API integration and green branding  
- Fixed API accuracy issues for correct Azure vote counts (4 cats, 3 dogs)
- Interactive deployment script supporting multiple deployment options
- Comprehensive documentation for symmetric architecture
- Tested: Azure app shows correct combined data, on-premises fixes in progress

Deployments available on ports 31514, 31515, 31516 with different feature sets
"@
    
    git commit -m $commitMessage
    
    Write-Host "📤 Pushing to GitHub..." -ForegroundColor Yellow
    git push origin main
    
    Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
}

# Generate deployment commands
if ($GitHubUser -eq "") {
    $GitHubUser = Read-Host "Enter your GitHub username"
}

Write-Host "`n🌐 GitHub Deployment Commands:" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$baseUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/main"

Write-Host "`n1️⃣ Full Symmetric On-Premises App (Port 31514):" -ForegroundColor Yellow
Write-Host "kubectl apply -f $baseUrl/cross-environment-voting-onprem.yaml" -ForegroundColor White

Write-Host "`n2️⃣ Quick Fix for Azure API Accuracy (Port 31515):" -ForegroundColor Yellow  
Write-Host "kubectl apply -f $baseUrl/quick-fix-onprem-azure-api.yaml" -ForegroundColor White

Write-Host "`n3️⃣ Simplified Green Theme (Port 31516):" -ForegroundColor Yellow
Write-Host "kubectl apply -f $baseUrl/quick-onprem-deploy-green.yaml" -ForegroundColor White

# Create a one-liner deployment script
$oneLinerScript = @"
#!/bin/bash
echo "🎯 Deploying Fixed On-Premises Voting App..."
kubectl apply -f $baseUrl/quick-fix-onprem-azure-api.yaml
echo "📍 App available at: http://66.242.207.21:31515"
echo "🧪 Test: curl http://66.242.207.21:31515/test-azure"
"@

Set-Content -Path "one-liner-deploy.sh" -Value $oneLinerScript
Write-Host "`n📝 Created 'one-liner-deploy.sh' for easy deployment" -ForegroundColor Green

Write-Host "`n🧪 Testing Commands:" -ForegroundColor Cyan
Write-Host "curl http://66.242.207.21:31515/test-azure  # Test Azure API connection"
Write-Host "curl http://66.242.207.21:31515/api/results # Check combined vote results"  
Write-Host "curl http://172.169.25.121/api/local-results # Verify Azure vote source (4 cats, 3 dogs)"

Write-Host "`n📊 Expected Results After Deployment:" -ForegroundColor Cyan
Write-Host "  Azure votes: 4 cats, 3 dogs"
Write-Host "  OnPrem votes: 10 cats, 4 dogs"
Write-Host "  Combined: 14 cats, 7 dogs (21 total votes)"

Write-Host "`n✨ Manual Git Commands (if git not available):" -ForegroundColor Magenta
Write-Host "1. Use GitHub Desktop or web interface"
Write-Host "2. Commit all files listed above" 
Write-Host "3. Push to main branch"
Write-Host "4. Use kubectl commands above to deploy from GitHub URLs"

Write-Host "`n🎉 Symmetric voting deployment ready!" -ForegroundColor Green
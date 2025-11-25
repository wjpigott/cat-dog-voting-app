# GitHub Repository Setup Script
# Automatically configures GitHub repository secrets and variables

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "azure-github-config.json",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "wjpigott/cat-dog-voting-app"
)

Write-Host "🔧 Setting up GitHub repository configuration..." -ForegroundColor Green

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file '$ConfigFile' not found. Please run Setup-Azure.ps1 first."
    exit 1
}

# Load configuration
$config = Get-Content $ConfigFile | ConvertFrom-Json

Write-Host "📝 Adding GitHub repository secrets..." -ForegroundColor Yellow

# Add secrets
try {
    gh secret set AZURE_CREDENTIALS --body $config.secrets.AZURE_CREDENTIALS --repo $RepoName
    Write-Host "✅ AZURE_CREDENTIALS secret added" -ForegroundColor Green
    
    gh secret set AZURE_CLIENT_SECRET --body $config.secrets.AZURE_CLIENT_SECRET --repo $RepoName
    Write-Host "✅ AZURE_CLIENT_SECRET secret added" -ForegroundColor Green
}
catch {
    Write-Error "Failed to add secrets: $($_.Exception.Message)"
    Write-Host "💡 You may need to add these manually in GitHub repository settings" -ForegroundColor Yellow
}

Write-Host "`n📋 Adding GitHub repository variables..." -ForegroundColor Yellow

# Add variables
try {
    gh variable set AZURE_RG --body $config.variables.AZURE_RG --repo $RepoName
    Write-Host "✅ AZURE_RG variable added" -ForegroundColor Green
    
    gh variable set AKS_CLUSTER_NAME --body $config.variables.AKS_CLUSTER_NAME --repo $RepoName
    Write-Host "✅ AKS_CLUSTER_NAME variable added" -ForegroundColor Green
    
    gh variable set AZURE_CLIENT_ID --body $config.variables.AZURE_CLIENT_ID --repo $RepoName
    Write-Host "✅ AZURE_CLIENT_ID variable added" -ForegroundColor Green
    
    gh variable set AZURE_TENANT_ID --body $config.variables.AZURE_TENANT_ID --repo $RepoName
    Write-Host "✅ AZURE_TENANT_ID variable added" -ForegroundColor Green
    
    gh variable set AZURE_SUBSCRIPTION_ID --body $config.variables.AZURE_SUBSCRIPTION_ID --repo $RepoName
    Write-Host "✅ AZURE_SUBSCRIPTION_ID variable added" -ForegroundColor Green
}
catch {
    Write-Error "Failed to add variables: $($_.Exception.Message)"
    Write-Host "💡 You may need to add these manually in GitHub repository settings" -ForegroundColor Yellow
}

Write-Host "`n🎉 GitHub repository setup complete!" -ForegroundColor Green
Write-Host "🔗 Repository: https://github.com/$RepoName" -ForegroundColor Cyan

# Enable GitHub Actions if not already enabled
Write-Host "`n🤖 Enabling GitHub Actions..." -ForegroundColor Yellow
try {
    gh api repos/$RepoName/actions/permissions --method PUT --field enabled=true
    Write-Host "✅ GitHub Actions enabled" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Could not automatically enable GitHub Actions. Please enable manually in repository settings." -ForegroundColor Yellow
}

Write-Host "`n🚀 Ready to deploy! Next steps:" -ForegroundColor Magenta
Write-Host "1. Set up your on-premises Azure Arc cluster" -ForegroundColor White
Write-Host "2. Push any changes to trigger the pipeline:" -ForegroundColor White
Write-Host "   git add . && git commit -m 'Setup complete' && git push" -ForegroundColor Gray
Write-Host "3. Or manually trigger the workflow:" -ForegroundColor White
Write-Host "   gh workflow run deploy-multi-env.yml --repo $RepoName" -ForegroundColor Gray
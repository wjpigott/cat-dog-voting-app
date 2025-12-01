# Configure Azure PostgreSQL Firewall for On-Premises Access
# This script adds firewall rules to allow on-premises K3s cluster to connect to Azure PostgreSQL

$ResourceGroup = "rg-cat-dog-voting-demo"
$ServerName = "postgres-cat-dog-voting"
$OnPremIP = "66.242.207.21"
$RuleName = "allow-onprem-k3s"

Write-Host "🔥 Configuring Azure PostgreSQL firewall rules..." -ForegroundColor Green
Write-Host "📍 Resource Group: $ResourceGroup"
Write-Host "🗄️  Server: $ServerName" 
Write-Host "🌐 On-premises IP: $OnPremIP"

# Add firewall rule for on-premises IP
Write-Host "➕ Adding firewall rule for on-premises access..." -ForegroundColor Yellow

try {
    az postgres server firewall-rule create `
      --resource-group $ResourceGroup `
      --server $ServerName `
      --name $RuleName `
      --start-ip-address $OnPremIP `
      --end-ip-address $OnPremIP

    Write-Host "✅ Successfully added firewall rule for $OnPremIP" -ForegroundColor Green
    
    # Verify firewall rules
    Write-Host "📋 Current firewall rules:" -ForegroundColor Cyan
    az postgres server firewall-rule list `
      --resource-group $ResourceGroup `
      --server $ServerName `
      --output table

    Write-Host "🎯 Azure PostgreSQL should now accept connections from on-premises K3s cluster!" -ForegroundColor Green
    Write-Host "🔄 The voting app should automatically pick up the Azure database connection." -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to add firewall rule: $_" -ForegroundColor Red
    exit 1
}
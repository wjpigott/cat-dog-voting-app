# Quick Azure PostgreSQL Setup for Cat/Dog Voting App
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "postgres-cat-dog-voting",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "voting_app",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUsername = "votinguser",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword = "SecureVotingPassword123!"
)

Write-Host "🐘 Creating Azure PostgreSQL Database" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if logged into Azure
try {
    $context = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Using Azure account: $($context.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Please run 'az login' first" -ForegroundColor Red
    exit 1
}

# Create Azure PostgreSQL Flexible Server
Write-Host "Creating PostgreSQL Flexible Server: $ServerName" -ForegroundColor Yellow
az postgres flexible-server create `
    --resource-group $ResourceGroup `
    --name $ServerName `
    --location $Location `
    --admin-user $AdminUsername `
    --admin-password $AdminPassword `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --storage-size 32 `
    --version 14 `
    --public-access 0.0.0.0 `
    --yes

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create PostgreSQL server" -ForegroundColor Red
    exit 1
}

# Create the voting_app database
Write-Host "Creating database: $DatabaseName" -ForegroundColor Yellow
az postgres flexible-server db create `
    --resource-group $ResourceGroup `
    --server-name $ServerName `
    --database-name $DatabaseName

# Get the server FQDN
$serverFQDN = az postgres flexible-server show `
    --resource-group $ResourceGroup `
    --name $ServerName `
    --query "fullyQualifiedDomainName" `
    --output tsv

Write-Host "✅ PostgreSQL server created!" -ForegroundColor Green
Write-Host "Server FQDN: $serverFQDN" -ForegroundColor Cyan
Write-Host "Database: $DatabaseName" -ForegroundColor Cyan
Write-Host "Username: $AdminUsername" -ForegroundColor Cyan

# Create votes table
Write-Host "Setting up database schema..." -ForegroundColor Yellow

$connectionString = "postgresql://${AdminUsername}:${AdminPassword}@${serverFQDN}:5432/${DatabaseName}?sslmode=require"

# Install psql client if needed (requires PostgreSQL client tools)
Write-Host "Note: Ensure PostgreSQL client tools are installed for schema setup" -ForegroundColor Yellow

$schemaSQL = @"
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_option VARCHAR(10) NOT NULL CHECK (vote_option IN ('cat', 'dog')),
    source VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_votes_option ON votes(vote_option);
CREATE INDEX IF NOT EXISTS idx_votes_source ON votes(source);

-- Insert test vote to verify
INSERT INTO votes (vote_option, source) VALUES ('cat', 'azure-test');
"@

# Save schema to temp file
$schemaFile = [System.IO.Path]::GetTempFileName() + ".sql"
$schemaSQL | Out-File -FilePath $schemaFile -Encoding UTF8

Write-Host "Schema SQL saved to: $schemaFile" -ForegroundColor Cyan
Write-Host "Run this command to set up the schema:" -ForegroundColor Yellow
Write-Host "psql `"$connectionString`" -f `"$schemaFile`"" -ForegroundColor White

# Output connection details for Azure deployment
Write-Host "`n🔧 Azure Deployment Environment Variables:" -ForegroundColor Green
Write-Host "DB_HOST=$serverFQDN" -ForegroundColor Cyan
Write-Host "DB_PORT=5432" -ForegroundColor Cyan  
Write-Host "DB_NAME=$DatabaseName" -ForegroundColor Cyan
Write-Host "DB_USER=$AdminUsername" -ForegroundColor Cyan
Write-Host "DB_PASSWORD=$AdminPassword" -ForegroundColor Cyan
Write-Host "VOTE_SOURCE=azure" -ForegroundColor Cyan

Write-Host "`n🚀 Next Steps:" -ForegroundColor Green
Write-Host "1. Run the psql command above to create the schema" -ForegroundColor White
Write-Host "2. Update your Azure AKS deployment with these environment variables" -ForegroundColor White
Write-Host "3. Deploy the voting app to Azure AKS" -ForegroundColor White
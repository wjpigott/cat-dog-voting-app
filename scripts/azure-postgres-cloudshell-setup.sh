#!/bin/bash
# Quick Azure PostgreSQL Setup for Cat/Dog Voting App
# Run this in Azure Cloud Shell: https://shell.azure.com

echo "🐘 Creating Azure PostgreSQL Database for Cat/Dog Voting App"
echo "============================================================"

# Variables
RESOURCE_GROUP="rg-cat-dog-voting-demo"
SERVER_NAME="postgres-cat-dog-voting"
LOCATION="eastus"
ADMIN_USER="votinguser"
ADMIN_PASSWORD="SecureVotingPassword123!"
DATABASE_NAME="voting_app"

# Create PostgreSQL Flexible Server
echo "📦 Creating PostgreSQL Flexible Server..."
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $SERVER_NAME \
  --location $LOCATION \
  --admin-user $ADMIN_USER \
  --admin-password $ADMIN_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 14 \
  --public-access 0.0.0.0 \
  --yes

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL server created successfully!"
else
    echo "❌ Failed to create PostgreSQL server. Exiting..."
    exit 1
fi

# Get server FQDN
echo "🔍 Getting server details..."
SERVER_FQDN=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name $SERVER_NAME \
  --query "fullyQualifiedDomainName" \
  --output tsv)

echo "📡 Server FQDN: $SERVER_FQDN"

# Create database
echo "💾 Creating voting_app database..."
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $SERVER_NAME \
  --database-name $DATABASE_NAME

# Wait a bit for server to be fully ready
echo "⏳ Waiting for server to be ready..."
sleep 30

# Create schema
echo "🏗️ Setting up database schema..."
export PGPASSWORD="$ADMIN_PASSWORD"

# Create the votes table
psql -h $SERVER_FQDN -p 5432 -U $ADMIN_USER -d $DATABASE_NAME -c "
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
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database schema created successfully!"
    echo ""
    echo "🎉 Azure PostgreSQL Database Setup Complete!"
    echo "============================================="
    echo "🔗 Server: $SERVER_FQDN"
    echo "💾 Database: $DATABASE_NAME"
    echo "👤 Username: $ADMIN_USER"
    echo "🔐 Password: $ADMIN_PASSWORD"
    echo ""
    echo "🚀 Environment Variables for Azure Deployment:"
    echo "DB_HOST=$SERVER_FQDN"
    echo "DB_PORT=5432"
    echo "DB_NAME=$DATABASE_NAME"
    echo "DB_USER=$ADMIN_USER" 
    echo "DB_PASSWORD=$ADMIN_PASSWORD"
    echo "VOTE_SOURCE=azure"
    echo ""
    echo "🔽 Next: Get AKS credentials and deploy the voting app:"
    echo "az aks get-credentials --resource-group $RESOURCE_GROUP --name aks-cat-dog-voting"
    echo "wget https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/azure-voting-app-with-azure-db.yaml"
    echo "kubectl apply -f azure-voting-app-with-azure-db.yaml"
else
    echo "❌ Failed to create database schema"
    exit 1
fi
#!/bin/bash
# Smart Azure PostgreSQL Setup - Tries multiple regions
# Run this in Azure Cloud Shell: https://shell.azure.com

echo "🐘 Creating Azure PostgreSQL Database for Cat/Dog Voting App"
echo "============================================================"

# Variables
RESOURCE_GROUP="rg-cat-dog-voting-demo"
SERVER_NAME="postgres-cat-dog-voting"
ADMIN_USER="votinguser"
ADMIN_PASSWORD="SecureVotingPassword123!"
DATABASE_NAME="voting_app"

# Try multiple regions in order of preference
REGIONS=("westus2" "eastus2" "centralus" "westeurope" "southeastasia" "eastus")

echo "🌍 Trying different regions for PostgreSQL availability..."

for LOCATION in "${REGIONS[@]}"; do
    echo ""
    echo "🔍 Trying region: $LOCATION"
    
    # Try to create PostgreSQL Flexible Server
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
      --yes \
      --output none
    
    if [ $? -eq 0 ]; then
        echo "✅ PostgreSQL server created successfully in $LOCATION!"
        SELECTED_LOCATION=$LOCATION
        break
    else
        echo "❌ Failed to create in $LOCATION, trying next region..."
        # Clean up any partial resources
        az postgres flexible-server delete --resource-group $RESOURCE_GROUP --name $SERVER_NAME --yes --output none 2>/dev/null
    fi
done

if [ -z "$SELECTED_LOCATION" ]; then
    echo "❌ Failed to create PostgreSQL server in any region. Please check your subscription limits or try again later."
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
echo "🌍 Location: $SELECTED_LOCATION"

# Create database
echo "💾 Creating voting_app database..."
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $SERVER_NAME \
  --database-name $DATABASE_NAME

# Wait a bit for server to be fully ready
echo "⏳ Waiting for server to be ready..."
sleep 45

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
    echo "🌍 Region: $SELECTED_LOCATION"
    echo "🔗 Server: $SERVER_FQDN"
    echo "💾 Database: $DATABASE_NAME"
    echo "👤 Username: $ADMIN_USER"
    echo "🔐 Password: $ADMIN_PASSWORD"
    echo ""
    echo "🚀 Updated Environment Variables for Azure Deployment:"
    echo "DB_HOST=$SERVER_FQDN"
    echo "DB_PORT=5432"
    echo "DB_NAME=$DATABASE_NAME"
    echo "DB_USER=$ADMIN_USER" 
    echo "DB_PASSWORD=$ADMIN_PASSWORD"
    echo "VOTE_SOURCE=azure"
    echo ""
    
    # Create updated deployment YAML with correct server name
    echo "📝 Creating updated deployment manifest..."
    cat > azure-voting-app-updated.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-azure
  labels:
    app: voting-app-azure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-app-azure
  template:
    metadata:
      labels:
        app: voting-app-azure
    spec:
      containers:
      - name: voting-app
        image: ghcr.io/wjpigott/voting-app-db:latest
        ports:
        - containerPort: 5000
        env:
        - name: VOTE_SOURCE
          value: "azure"
        - name: DB_HOST
          value: "$SERVER_FQDN"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "voting_app"
        - name: DB_USER
          value: "votinguser"
        - name: DB_PASSWORD
          value: "SecureVotingPassword123!"
---
apiVersion: v1
kind: Service
metadata:
  name: voting-app-azure-service
  labels:
    app: voting-app-azure
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: voting-app-azure
EOF
    
    echo "✅ Updated deployment manifest created as azure-voting-app-updated.yaml"
    echo ""
    echo "🔽 Next: Deploy the voting app:"
    echo "az aks get-credentials --resource-group $RESOURCE_GROUP --name aks-cat-dog-voting"
    echo "kubectl apply -f azure-voting-app-updated.yaml"
    echo "kubectl get svc voting-app-azure-service -w"
else
    echo "❌ Failed to create database schema"
    exit 1
fi
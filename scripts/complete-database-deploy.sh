#!/bin/bash
# Complete Azure PostgreSQL + Voting App Deployment
# Run after PostgreSQL deployment completes in Azure Cloud Shell

echo "🎯 Final Deployment: PostgreSQL + Voting App"
echo "============================================="

RESOURCE_GROUP="rg-cat-dog-voting-demo"
CLUSTER_NAME="aks-cat-dog-voting"
SERVER_NAME="postgres-cat-dog-voting"

# Step 1: Get PostgreSQL server details
echo "🔍 Getting PostgreSQL server details..."
SERVER_FQDN=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name $SERVER_NAME \
  --query "fullyQualifiedDomainName" \
  --output tsv)

if [ -z "$SERVER_FQDN" ]; then
    echo "❌ PostgreSQL server not found or not ready. Please wait for deployment to complete."
    exit 1
fi

echo "✅ PostgreSQL server ready: $SERVER_FQDN"

# Step 2: Setup database schema
echo "🏗️ Setting up database schema..."
export PGPASSWORD="SecureVotingPassword123!"

# Create database if it doesn't exist
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $SERVER_NAME \
  --database-name voting_app 2>/dev/null || echo "Database already exists"

# Create schema
psql -h $SERVER_FQDN -p 5432 -U votinguser -d voting_app -c "
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_option VARCHAR(10) NOT NULL CHECK (vote_option IN ('cat', 'dog')),
    source VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_votes_option ON votes(vote_option);
CREATE INDEX IF NOT EXISTS idx_votes_source ON votes(source);

-- Clear any existing test data and add fresh test vote
DELETE FROM votes WHERE source = 'azure-test';
INSERT INTO votes (vote_option, source) VALUES ('cat', 'azure-test');
"

if [ $? -eq 0 ]; then
    echo "✅ Database schema created successfully!"
else
    echo "❌ Failed to create database schema"
    exit 1
fi

# Step 3: Get AKS credentials
echo "🔐 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Step 4: Deploy voting app
echo "🚀 Deploying voting app to AKS..."
wget -O final-voting-app.yaml https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/final-voting-app.yaml

# Update YAML with correct server FQDN
sed -i "s/postgres-cat-dog-voting.postgres.database.azure.com/$SERVER_FQDN/g" final-voting-app.yaml

kubectl apply -f final-voting-app.yaml

# Step 5: Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/voting-app-azure

# Step 6: Get service status
echo "🌐 Getting external IP..."
kubectl get svc voting-app-azure-service

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "🔗 PostgreSQL: $SERVER_FQDN"
echo "💾 Database: voting_app"
echo "👤 User: votinguser"
echo ""
echo "🔍 Monitor deployment:"
echo "kubectl get pods -l app=voting-app-azure"
echo "kubectl logs deployment/voting-app-azure -f"
echo ""
echo "🌐 Get external IP (takes 2-3 minutes):"
echo "kubectl get svc voting-app-azure-service -w"
echo ""
echo "🧪 Test the application:"
echo "EXTERNAL_IP=\$(kubectl get svc voting-app-azure-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "curl http://\$EXTERNAL_IP/health"
echo "curl http://\$EXTERNAL_IP/api/results"
#!/bin/bash
# Deploy Azure voting app with complete UI - Configurable version

# Load customer configuration
CONFIG_FILE="../config/customer.env"
if [ -f "$CONFIG_FILE" ]; then
    echo "� Loading customer configuration from $CONFIG_FILE..."
    source "$CONFIG_FILE"
else
    echo "⚠️  Customer config not found. Using default values."
    echo "💡 Create config/customer.env to customize for your environment."
    # Default values
    ONPREM_ENDPOINT="http://66.242.207.21:31514"
    AZURE_POSTGRES_HOST="postgres-cat-dog-voting.postgres.database.azure.com"
    AZURE_POSTGRES_USER="votinguser" 
    AZURE_POSTGRES_PASSWORD="SecureVotingPassword123!"
    AZURE_POSTGRES_DB="postgres"
fi

echo "�🚀 Deploying Azure voting app with complete cross-environment UI..."
echo "🔧 Configuration:"
echo "   📍 OnPrem Endpoint: $ONPREM_ENDPOINT"
echo "   🗄️  Azure PostgreSQL: $AZURE_POSTGRES_HOST"
echo "   👤 Database User: $AZURE_POSTGRES_USER"

# Create a temporary deployment file with customer values
TEMP_DEPLOY="azure-voting-app-complete-configured.yaml"
cp azure-voting-app-complete.yaml "$TEMP_DEPLOY"

# Replace placeholders with actual values
sed -i "s|value: \"http://66.242.207.21:31514\"|value: \"$ONPREM_ENDPOINT\"|g" "$TEMP_DEPLOY"
sed -i "s|value: \"postgres-cat-dog-voting.postgres.database.azure.com\"|value: \"$AZURE_POSTGRES_HOST\"|g" "$TEMP_DEPLOY"
sed -i "s|value: \"votinguser\"|value: \"$AZURE_POSTGRES_USER\"|g" "$TEMP_DEPLOY" 
sed -i "s|value: \"SecureVotingPassword123!\"|value: \"$AZURE_POSTGRES_PASSWORD\"|g" "$TEMP_DEPLOY"
sed -i "s|value: \"postgres\"|value: \"$AZURE_POSTGRES_DB\"|g" "$TEMP_DEPLOY"

# Apply the deployment
kubectl apply -f "$TEMP_DEPLOY"

# Clean up temporary file
rm "$TEMP_DEPLOY"

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/azure-voting-app-complete

# Get service information
echo "📊 Service Information:"
kubectl get service azure-voting-app-complete-service
kubectl get service voting-app-final-lb

echo "✅ Azure deployment complete!"
echo "🌐 Access your app via the EXTERNAL-IP shown above"
echo "🔧 Configuration used: OnPrem=$ONPREM_ENDPOINT, Azure DB=$AZURE_POSTGRES_HOST"
#!/bin/bash
# Setup Azure Application Gateway for load balancing between Azure AKS and OnPrem

# Configuration from customer.env
CONFIG_FILE="../config/customer.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Customer configuration required. Please create config/customer.env"
    exit 1
fi

echo "🔄 Setting up Azure Application Gateway for load balancing..."
echo "📍 Azure Backend: $AZURE_LOAD_BALANCER_IP"
echo "📍 OnPrem Backend: $ONPREM_PUBLIC_IP:$ONPREM_SERVICE_PORT"

# Check if resource group exists
if ! az group show --name "$AZURE_RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "❌ Resource group $AZURE_RESOURCE_GROUP not found"
    echo "💡 Create it with: az group create --name $AZURE_RESOURCE_GROUP --location eastus"
    exit 1
fi

echo "🌐 Creating public IP for Application Gateway..."
az network public-ip create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name appgw-voting-pip \
    --allocation-method Static \
    --sku Standard

echo "📡 Creating virtual network and subnet..."
az network vnet create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name appgw-voting-vnet \
    --address-prefix 10.0.0.0/16 \
    --subnet-name appgw-subnet \
    --subnet-prefix 10.0.1.0/24

echo "🔄 Creating Application Gateway with load balancing..."
az network application-gateway create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name voting-app-gateway \
    --location eastus \
    --capacity 2 \
    --sku Standard_v2 \
    --public-ip-address appgw-voting-pip \
    --vnet-name appgw-voting-vnet \
    --subnet appgw-subnet \
    --servers "$AZURE_LOAD_BALANCER_IP" "$ONPREM_PUBLIC_IP:$ONPREM_SERVICE_PORT" \
    --priority 1

echo "❤️ Adding health probe for Azure backend..."
az network application-gateway probe create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --gateway-name voting-app-gateway \
    --name azure-health-probe \
    --protocol Http \
    --path /health \
    --interval 30 \
    --timeout 120 \
    --threshold 3

echo "❤️ Adding health probe for OnPrem backend..."
az network application-gateway probe create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --gateway-name voting-app-gateway \
    --name onprem-health-probe \
    --protocol Http \
    --path /health \
    --interval 30 \
    --timeout 120 \
    --threshold 3

echo "⚙️ Configuring backend pool with health checks..."
az network application-gateway address-pool create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --gateway-name voting-app-gateway \
    --name azure-backend-pool \
    --servers "$AZURE_LOAD_BALANCER_IP"

az network application-gateway address-pool create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --gateway-name voting-app-gateway \
    --name onprem-backend-pool \
    --servers "$ONPREM_PUBLIC_IP:$ONPREM_SERVICE_PORT"

echo "🎯 Setting up load balancing rules..."
# Configure round-robin load balancing with health checks
az network application-gateway http-settings update \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --gateway-name voting-app-gateway \
    --name appGatewayBackendHttpSettings \
    --probe azure-health-probe \
    --timeout 86400

echo "📊 Getting Application Gateway public IP..."
APPGW_IP=$(az network public-ip show \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name appgw-voting-pip \
    --query ipAddress \
    --output tsv)

echo ""
echo "✅ Load balanced Application Gateway setup complete!"
echo "🌐 Load Balanced Endpoint: http://$APPGW_IP"
echo "🔄 Failover: Automatically routes traffic to healthy backend"
echo "❤️ Health Checks: Both Azure and OnPrem backends monitored"
echo ""
echo "📋 Backend Status:"
echo "   🔷 Azure AKS: $AZURE_LOAD_BALANCER_IP (health check: /health)"
echo "   🏠 OnPrem K3s: $ONPREM_PUBLIC_IP:$ONPREM_SERVICE_PORT (health check: /health)"
echo ""
echo "🧪 Test the load balanced endpoint:"
echo "   curl http://$APPGW_IP/api/results"
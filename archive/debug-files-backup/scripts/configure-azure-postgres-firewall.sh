#!/bin/bash

# Configure Azure PostgreSQL Firewall for On-Premises Access
# This script adds firewall rules to allow on-premises K3s cluster to connect to Azure PostgreSQL

RESOURCE_GROUP="rg-cat-dog-voting-demo"
SERVER_NAME="postgres-cat-dog-voting"
ONPREM_IP="66.242.207.21"
RULE_NAME="allow-onprem-k3s"

echo "🔥 Configuring Azure PostgreSQL firewall rules..."
echo "📍 Resource Group: $RESOURCE_GROUP"
echo "🗄️  Server: $SERVER_NAME" 
echo "🌐 On-premises IP: $ONPREM_IP"

# Add firewall rule for on-premises IP
echo "➕ Adding firewall rule for on-premises access..."
az postgres server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SERVER_NAME \
  --name $RULE_NAME \
  --start-ip-address $ONPREM_IP \
  --end-ip-address $ONPREM_IP

if [ $? -eq 0 ]; then
    echo "✅ Successfully added firewall rule for $ONPREM_IP"
else
    echo "❌ Failed to add firewall rule"
    exit 1
fi

# Verify firewall rules
echo "📋 Current firewall rules:"
az postgres server firewall-rule list \
  --resource-group $RESOURCE_GROUP \
  --server $SERVER_NAME \
  --output table

echo "🎯 Azure PostgreSQL should now accept connections from on-premises K3s cluster!"
echo "🔄 The voting app should automatically pick up the Azure database connection."
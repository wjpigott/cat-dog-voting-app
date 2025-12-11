#!/bin/bash

# Azure Traffic Manager Deployment Script
# Deploys Traffic Manager with automatic failover between Azure AKS and On-Premises

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP="rg-cat-dog-voting"
LOCATION="centralus"
PROFILE_NAME="voting-app-tm-$(date +%s | tail -c 5)"
AZURE_ENDPOINT="52.154.54.110"
ONPREM_ENDPOINT="66.242.207.21"
ONPREM_PORT="31514"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Azure Traffic Manager Deployment Script${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"

# Function to check if Azure CLI is logged in
check_azure_login() {
    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}⚠️  Not logged into Azure CLI${NC}"
        echo -e "${BLUE}🔑 Logging in...${NC}"
        az login
    else
        echo -e "${GREEN}✅ Already logged into Azure CLI${NC}"
        CURRENT_ACCOUNT=$(az account show --query "name" -o tsv)
        echo -e "${CYAN}� Current account: $CURRENT_ACCOUNT${NC}"
    fi
}

# Function to ensure resource group exists
ensure_resource_group() {
    echo -e "${BLUE}🔄 Checking resource group: $RESOURCE_GROUP${NC}"
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        echo -e "${YELLOW}� Creating resource group: $RESOURCE_GROUP${NC}"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        echo -e "${GREEN}✅ Resource group created${NC}"
    else
        echo -e "${GREEN}✅ Resource group exists${NC}"
    fi
}

# Function to test endpoint health
test_endpoint() {
    local endpoint=$1
    local name=$2
    echo -e "${BLUE}🔍 Testing $name endpoint: $endpoint${NC}"
    
    if curl -f -s --max-time 10 "$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name is healthy${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $name is not responding${NC}"
        return 1
    fi
}

# Function to create Traffic Manager profile
create_traffic_manager() {
    echo -e "${BLUE}🌐 Creating Traffic Manager profile: $PROFILE_NAME${NC}"
    
    az network traffic-manager profile create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$PROFILE_NAME" \
        --routing-method Priority \
        --unique-dns-name "$PROFILE_NAME" \
        --ttl 30 \
        --protocol HTTP \
        --port 80 \
        --path "/" \
        --interval 30 \
        --timeout 10 \
        --max-failures 3 \
        --output table
    
    echo -e "${GREEN}✅ Traffic Manager profile created${NC}"
}

# Function to add endpoints
add_endpoints() {
    echo -e "${BLUE}🎯 Adding Azure AKS endpoint (Primary)${NC}"
    az network traffic-manager endpoint create \
        --resource-group "$RESOURCE_GROUP" \
        --profile-name "$PROFILE_NAME" \
        --name "azure-aks-primary" \
        --type externalEndpoints \
        --target "$AZURE_ENDPOINT" \
        --priority 1 \
        --endpoint-status Enabled \
        --output table

    echo -e "${GREEN}✅ Azure endpoint added${NC}"

    echo -e "${BLUE}🏠 Adding OnPrem endpoint (Backup)${NC}"
    az network traffic-manager endpoint create \
        --resource-group "$RESOURCE_GROUP" \
        --profile-name "$PROFILE_NAME" \
        --name "onprem-backup" \
        --type externalEndpoints \
        --target "$ONPREM_ENDPOINT" \
        --priority 2 \
        --endpoint-status Enabled \
        --output table

    echo -e "${GREEN}✅ OnPrem endpoint added${NC}"
}

# Function to get Traffic Manager info
show_results() {
    echo -e "${MAGENTA}🎉 Traffic Manager Deployment Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    # Get the FQDN
    TM_FQDN=$(az network traffic-manager profile show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$PROFILE_NAME" \
        --query "dnsConfig.fqdn" \
        --output tsv)
    
    echo -e "${GREEN}🌐 Your Traffic Manager URL:${NC}"
    echo -e "${YELLOW}   http://$TM_FQDN${NC}"
    echo
    echo -e "${GREEN}📊 Endpoint Configuration:${NC}"
    echo -e "${CYAN}   Primary: $AZURE_ENDPOINT (Azure AKS - Priority 1)${NC}"
    echo -e "${CYAN}   Backup:  $ONPREM_ENDPOINT:$ONPREM_PORT (OnPrem K3s - Priority 2)${NC}"
    echo
    echo -e "${GREEN}⚡ Failover Configuration:${NC}"
    echo -e "${CYAN}   - Health checks every 30 seconds${NC}"
    echo -e "${CYAN}   - 3 failures trigger automatic failover${NC}"
    echo -e "${CYAN}   - 10 second timeout per check${NC}"
    echo -e "${CYAN}   - Priority routing: Azure first, OnPrem backup${NC}"
    echo
    echo -e "${YELLOW}🧪 Test your setup:${NC}"
    echo -e "${CYAN}   curl http://$TM_FQDN${NC}"
    echo -e "${CYAN}   # Should route to Azure when healthy${NC}"
    echo
    echo -e "${YELLOW}🔄 Test failover:${NC}"
    echo -e "${CYAN}   1. Shut down AKS cluster${NC}"
    echo -e "${CYAN}   2. Wait 2-3 minutes for health check failures${NC}"
    echo -e "${CYAN}   3. Access URL - should route to OnPrem${NC}"
    echo -e "${CYAN}   4. Start AKS - should fail back automatically${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}📋 Configuration:${NC}"
    echo -e "${CYAN}   Resource Group: $RESOURCE_GROUP${NC}"
    echo -e "${CYAN}   Profile Name: $PROFILE_NAME${NC}"
    echo -e "${CYAN}   Azure Endpoint: $AZURE_ENDPOINT${NC}"
    echo -e "${CYAN}   OnPrem Endpoint: $ONPREM_ENDPOINT:$ONPREM_PORT${NC}"
    echo

    # Test endpoints first
    echo -e "${BLUE}🔍 Testing endpoint health...${NC}"
    test_endpoint "http://$AZURE_ENDPOINT" "Azure AKS"
    test_endpoint "http://$ONPREM_ENDPOINT:$ONPREM_PORT" "OnPrem K3s"
    echo

    # Login and setup
    check_azure_login
    ensure_resource_group
    
    # Deploy Traffic Manager
    create_traffic_manager
    add_endpoints
    
    # Show results
    show_results
}

# Error handling
trap 'echo -e "${RED}❌ Error occurred. Check Azure CLI permissions and network connectivity.${NC}"; exit 1' ERR

# Run main function
main
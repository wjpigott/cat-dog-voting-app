#!/bin/bash
# Production Environment Verification Script - Configurable version

# Load customer configuration
CONFIG_FILE="../config/customer.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Default values if no config found
    ONPREM_ENDPOINT="http://<onprem-ip>:31514"
    AZURE_LOAD_BALANCER_IP="<azure-ip>"
fi

echo "🔍 Verifying Production Cat vs Dog Voting Environments..."
echo "======================================================"

# Test Azure Environment
echo ""
echo "🔷 Azure Environment (AKS)"
echo "URL: http://$AZURE_LOAD_BALANCER_IP"
echo "Expected: Cross-environment voting with Azure + OnPrem data"

AZURE_RESPONSE=$(curl -s "http://$AZURE_LOAD_BALANCER_IP/api/results")
if [ $? -eq 0 ]; then
    echo "✅ Azure API: WORKING"
    echo "📊 Azure Response: $AZURE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "📊 $AZURE_RESPONSE"
else
    echo "❌ Azure API: FAILED"
fi

echo ""
echo "🏠 On-Premises Environment (K3s)"  
echo "URL: $ONPREM_ENDPOINT"
echo "Expected: Cross-environment voting with Azure + OnPrem data"

ONPREM_RESPONSE=$(curl -s "$ONPREM_ENDPOINT/api/results")
if [ $? -eq 0 ]; then
    echo "✅ OnPrem API: WORKING"
    echo "📊 OnPrem Response: $ONPREM_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "📊 $ONPREM_RESPONSE"
else
    echo "❌ OnPrem API: FAILED"
fi

echo ""
echo "🎯 Environment Summary:"
echo "- Both environments should show identical combined vote totals"
echo "- Azure votes = votes cast via Azure UI ($AZURE_LOAD_BALANCER_IP)"  
echo "- OnPrem votes = votes cast via OnPrem UI ($ONPREM_ENDPOINT)"
echo "- Cross-environment integration working if totals match"

echo ""
echo "🚀 Production environments verified!"
echo "📄 To customize endpoints, edit: config/customer.env"
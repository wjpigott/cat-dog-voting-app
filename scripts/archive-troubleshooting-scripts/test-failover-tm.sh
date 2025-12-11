#!/bin/bash

# Traffic Manager Failover Testing Script
# Tests automatic failover between Azure and OnPrem endpoints

TRAFFIC_MANAGER_URL="${1:-}"
AZURE_ENDPOINT="${2:-http://52.154.54.110}"
ONPREM_ENDPOINT="${3:-http://66.242.207.21:31514}"
TEST_DURATION="${4:-300}"  # 5 minutes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m'

echo -e "${MAGENTA}🧪 TRAFFIC MANAGER FAILOVER TEST${NC}"
echo -e "${GRAY}═══════════════════════════════════════${NC}"

if [[ -z "$TRAFFIC_MANAGER_URL" ]]; then
    echo -e "${YELLOW}⚠️  Traffic Manager URL required${NC}"
    echo -e "${GRAY}Usage: $0 <traffic-manager-url> [azure-endpoint] [onprem-endpoint] [duration]${NC}"
    echo -e "${GRAY}Example: $0 'http://voting-app-tm-xxxx.trafficmanager.net'${NC}"
    exit 1
fi

# Function to test endpoint health
test_endpoint_health() {
    local endpoint=$1
    local name=$2
    
    if curl -f -s --max-time 5 "$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name: UP${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: DOWN${NC}"
        return 1
    fi
}

# Function to test Traffic Manager routing
test_traffic_manager() {
    local tm_url=$1
    
    if curl -f -s --max-time 10 "$tm_url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Traffic Manager: ROUTING${NC}"
        return 0
    else
        echo -e "${RED}❌ Traffic Manager: FAILED${NC}"
        return 1
    fi
}

# Function to detect current backend
get_current_backend() {
    local tm_url=$1
    
    # Try to get response and analyze content
    local response=$(curl -s --max-time 10 "$tm_url" 2>/dev/null || echo "")
    
    if [[ $response == *"azure"* ]] || [[ $response == *"AKS"* ]]; then
        echo "🔷 Azure AKS"
    elif [[ $response == *"onprem"* ]] || [[ $response == *"k3s"* ]] || [[ $response == *"66.242.207.21"* ]]; then
        echo "🏠 OnPrem K3s"
    else
        echo "❓ Unknown Backend"
    fi
}

echo -e "${CYAN}📋 Test Configuration:${NC}"
echo -e "${YELLOW}   Traffic Manager: $TRAFFIC_MANAGER_URL${NC}"
echo -e "${YELLOW}   Azure Endpoint: $AZURE_ENDPOINT${NC}"
echo -e "${YELLOW}   OnPrem Endpoint: $ONPREM_ENDPOINT${NC}"
echo -e "${YELLOW}   Test Duration: $TEST_DURATION seconds${NC}"
echo

# Initial health check
echo -e "${BLUE}🔍 Initial Health Check:${NC}"
test_endpoint_health "$AZURE_ENDPOINT" "Azure AKS"
test_endpoint_health "$ONPREM_ENDPOINT" "OnPrem K3s"
test_traffic_manager "$TRAFFIC_MANAGER_URL"

current_backend=$(get_current_backend "$TRAFFIC_MANAGER_URL")
echo -e "${MAGENTA}   Current Backend: $current_backend${NC}"
echo

# Continuous monitoring
echo -e "${GREEN}🔄 Starting Continuous Monitoring...${NC}"
echo -e "${GRAY}Press Ctrl+C to stop monitoring${NC}"
echo

start_time=$(date +%s)
test_count=0
last_backend=""

while [[ $(($(date +%s) - start_time)) -lt $TEST_DURATION ]]; do
    ((test_count++))
    
    # Clear screen and show status
    clear
    echo -e "${MAGENTA}🧪 TRAFFIC MANAGER FAILOVER TEST - Check #$test_count${NC}"
    echo -e "${GRAY}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GRAY}🕐 $(date '+%Y-%m-%d %H:%M:%S') | Elapsed: $(($(date +%s) - start_time))s${NC}"
    echo
    
    # Test all endpoints
    echo -e "${CYAN}📊 Endpoint Status:${NC}"
    azure_healthy=false
    onprem_healthy=false
    tm_healthy=false
    
    if test_endpoint_health "$AZURE_ENDPOINT" "Azure AKS"; then
        azure_healthy=true
    fi
    
    if test_endpoint_health "$ONPREM_ENDPOINT" "OnPrem K3s"; then
        onprem_healthy=true
    fi
    
    if test_traffic_manager "$TRAFFIC_MANAGER_URL"; then
        tm_healthy=true
    fi
    
    echo
    
    # Show routing decision
    if [[ "$tm_healthy" == "true" ]]; then
        current_backend=$(get_current_backend "$TRAFFIC_MANAGER_URL")
        echo -e "${YELLOW}🎯 Current Routing:${NC}"
        echo -e "${MAGENTA}   Active Backend: $current_backend${NC}"
        
        # Detect failover
        if [[ -n "$last_backend" && "$last_backend" != "$current_backend" ]]; then
            echo -e "${RED}   🚨 FAILOVER DETECTED!${NC}"
            echo -e "${GRAY}   Changed from: $last_backend${NC}"
            echo -e "${GRAY}   Changed to: $current_backend${NC}"
        fi
        last_backend="$current_backend"
    fi
    
    # Show expected routing
    echo -e "${BLUE}🤔 Expected Routing Logic:${NC}"
    if [[ "$azure_healthy" == "true" && "$onprem_healthy" == "true" ]]; then
        echo -e "${GREEN}   Both UP → Should route to Azure (Priority 1)${NC}"
    elif [[ "$azure_healthy" == "true" && "$onprem_healthy" == "false" ]]; then
        echo -e "${YELLOW}   Only Azure UP → Should route to Azure${NC}"
    elif [[ "$azure_healthy" == "false" && "$onprem_healthy" == "true" ]]; then
        echo -e "${YELLOW}   Only OnPrem UP → Should route to OnPrem${NC}"
    else
        echo -e "${RED}   Both DOWN → Traffic Manager should return error${NC}"
    fi
    
    echo
    echo -e "${CYAN}🧪 Failover Test Instructions:${NC}"
    echo -e "${GRAY}   1. Keep this monitor running${NC}"
    echo -e "${GRAY}   2. In another terminal, shut down AKS cluster${NC}"
    echo -e "${GRAY}   3. Watch for automatic failover to OnPrem${NC}"
    echo -e "${GRAY}   4. Start AKS cluster back up${NC}"
    echo -e "${GRAY}   5. Watch for automatic failback to Azure${NC}"
    
    sleep 15
done

echo
echo -e "${GREEN}✅ Test completed!${NC}"
echo -e "${GRAY}Check the log above for any detected failovers.${NC}"
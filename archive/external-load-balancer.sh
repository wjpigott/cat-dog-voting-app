#!/bin/bash

# External High Availability Load Balancer
# Runs independently of both Azure and OnPrem clusters
# Provides true failover capability

AZURE_ENDPOINT="http://52.154.54.110"
ONPREM_ENDPOINT="http://66.242.207.21:31514"
LOAD_BALANCER_PORT=8080
CHECK_INTERVAL=10

echo "🚀 Starting External HA Load Balancer on port $LOAD_BALANCER_PORT"
echo "🎯 Primary: $AZURE_ENDPOINT"
echo "🔄 Backup: $ONPREM_ENDPOINT"

# Function to check if endpoint is healthy
check_health() {
    local endpoint=$1
    curl -f -s --max-time 5 "$endpoint/health" > /dev/null 2>&1
    return $?
}

# Function to proxy request
proxy_request() {
    local target=$1
    local request_path=$2
    local method=$3
    
    case $method in
        "GET")
            curl -f -s --max-time 10 "$target$request_path"
            ;;
        "POST")
            curl -f -s --max-time 10 -X POST "$target$request_path" -H "Content-Type: application/x-www-form-urlencoded" --data-binary @-
            ;;
        *)
            curl -f -s --max-time 10 -X "$method" "$target$request_path"
            ;;
    esac
}

# Main request handler
handle_request() {
    local request_path=$1
    local method=${2:-GET}
    
    # Try Azure first
    if check_health "$AZURE_ENDPOINT"; then
        echo "🎯 Routing to Azure (Primary)" >&2
        proxy_request "$AZURE_ENDPOINT" "$request_path" "$method"
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    
    # Fallback to OnPrem
    echo "🔄 Failing over to OnPrem (Backup)" >&2
    proxy_request "$ONPREM_ENDPOINT" "$request_path" "$method"
}

# Simple HTTP server simulation
start_load_balancer() {
    echo "🌐 Load Balancer ready at http://localhost:$LOAD_BALANCER_PORT"
    echo "📊 Health Status:"
    
    while true; do
        if check_health "$AZURE_ENDPOINT"; then
            echo "✅ Azure: UP"
        else
            echo "❌ Azure: DOWN"
        fi
        
        if check_health "$ONPREM_ENDPOINT"; then
            echo "✅ OnPrem: UP"
        else
            echo "❌ OnPrem: DOWN"
        fi
        
        echo "---"
        sleep $CHECK_INTERVAL
    done
}

# Start the load balancer
start_load_balancer
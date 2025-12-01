#!/bin/bash
# Test Load Balancer Failover Functionality

# Configuration
CONFIG_FILE="../config/customer.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Get load balancer IP
LB_IP=$(kubectl get service voting-load-balancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$LB_IP" ]; then
    echo "❌ Load balancer service not ready yet"
    echo "💡 Run: kubectl get service voting-load-balancer-service"
    exit 1
fi

echo "🔄 Testing Load Balancer Failover Capabilities"
echo "================================================"
echo "🎯 Load Balancer: http://$LB_IP"
echo ""

echo "1️⃣ Testing Load Balancer Health..."
curl -s "http://$LB_IP/health"
echo ""

echo ""
echo "2️⃣ Testing Backend Status..."
curl -s "http://$LB_IP/lb-status" 
echo ""

echo ""
echo "3️⃣ Testing Load Balanced API (should work even if one backend fails)..."
for i in {1..5}; do
    echo "Request #$i:"
    RESPONSE=$(curl -s "http://$LB_IP/api/results" -w "Status: %{http_code}")
    echo "$RESPONSE" | head -1 | jq -r '"Environment: " + .environment + " | Total Votes: " + (.total_votes | tostring)'
    sleep 1
done

echo ""
echo "4️⃣ Testing Individual Backends (for comparison)..."

echo "🔷 Direct Azure Backend:"
curl -s "http://52.154.54.110/api/results" | jq -r '"Environment: " + .environment + " | Total Votes: " + (.total_votes | tostring)' 2>/dev/null || echo "❌ Azure backend unreachable"

echo "🏠 Direct OnPrem Backend:" 
curl -s "http://66.242.207.21:31514/api/results" | jq -r '"Environment: " + .environment + " | Total Votes: " + (.total_votes | tostring)' 2>/dev/null || echo "❌ OnPrem backend unreachable"

echo ""
echo "🎯 Load Balancer Results:"
echo "✅ Load Balancer IP: http://$LB_IP"
echo "⚖️  Traffic Distribution: 75% Azure (weight 3) / 25% OnPrem (weight 1)"
echo "🔄 Failover: Automatic if backend fails (2 failures = 30s timeout)"
echo "❤️ Health Checks: /health endpoint on both backends"

echo ""
echo "🧪 To Test Failover Manually:"
echo "   1. Stop one environment: kubectl delete deployment azure-voting-app-complete"
echo "   2. Test load balancer: curl http://$LB_IP/api/results"  
echo "   3. Should automatically failover to healthy backend"
echo "   4. Restart stopped environment to restore full load balancing"
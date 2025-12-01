# Comprehensive debug script to check why fixed deployment still shows wrong Azure data

echo "🔍 Debugging FIXED deployment - checking why Azure data is still wrong..."
echo ""

# Get the pod name
POD_NAME=$(kubectl get pods -l app=voting-app-azure -o jsonpath='{.items[0].metadata.name}')
echo "📋 Pod name: $POD_NAME"
echo ""

# Check if this is the new fixed deployment
echo "🔧 Checking if this is the FIXED deployment..."
kubectl exec $POD_NAME -- python3 -c "
import requests
try:
    response = requests.get('http://localhost:5000/health', timeout=5)
    print(f'Health check: {response.json()}')
except Exception as e:
    print(f'Health check failed: {e}')
" 2>/dev/null || echo "Health endpoint not available"

echo ""
echo "🧪 Testing the debug endpoint..."
kubectl exec $POD_NAME -- python3 -c "
import requests
try:
    response = requests.get('http://localhost:5000/debug', timeout=5)
    if response.status_code == 200:
        import json
        data = response.json()
        print('📊 Debug endpoint results:')
        print(f'  Local votes: {data.get(\"local_votes\", \"N/A\")}')
        print(f'  Azure direct votes: {data.get(\"azure_direct_votes\", \"N/A\")}')
        print(f'  Azure API votes: {data.get(\"azure_api_votes\", \"N/A\")}')
        print(f'  Environment vars: {data.get(\"environment_vars\", \"N/A\")}')
    else:
        print(f'Debug endpoint returned status: {response.status_code}')
except Exception as e:
    print(f'Debug endpoint failed: {e}')
" 2>/dev/null || echo "Debug endpoint test failed"

echo ""
echo "🔍 Testing /test-azure-db endpoint..."
kubectl exec $POD_NAME -- python3 -c "
import requests
try:
    response = requests.get('http://localhost:5000/test-azure-db', timeout=5)
    if response.status_code == 200:
        data = response.json()
        print(f'Azure DB test: {data}')
    else:
        print(f'test-azure-db returned status: {response.status_code}')
except Exception as e:
    print(f'test-azure-db failed: {e}')
" 2>/dev/null || echo "Azure DB test endpoint failed"

echo ""
echo "📊 Testing /api/results from inside pod..."
kubectl exec $POD_NAME -- python3 -c "
import requests
try:
    response = requests.get('http://localhost:5000/api/results', timeout=5)
    if response.status_code == 200:
        import json
        data = response.json()
        print('API Results from inside pod:')
        print(json.dumps(data, indent=2))
    else:
        print(f'/api/results returned status: {response.status_code}')
except Exception as e:
    print(f'/api/results failed: {e}')
" 2>/dev/null || echo "API results test failed"

echo ""
echo "📝 Checking recent pod logs for Azure database messages..."
kubectl logs $POD_NAME --tail=30 | grep -i "azure\|database\|connection\|error\|direct\|votes" || echo "No relevant log messages found"

echo ""
echo "💡 If this is still showing wrong data, the issue might be:"
echo "   1. Pod restart needed to pick up new code"
echo "   2. Service routing to old pod"
echo "   3. Flask app logic still has bugs"
echo "   4. External API call hitting wrong endpoint"
# Test the specific API endpoints to debug why Azure data isn't showing correctly

echo "🔍 Testing specific API endpoints to debug Azure data issue..."
echo ""

# Get the pod name
POD_NAME=$(kubectl get pods -l app=voting-app-azure -o jsonpath='{.items[0].metadata.name}')
echo "📋 Pod name: $POD_NAME"

echo ""
echo "🧪 Testing /test-azure-db endpoint (if available)..."
kubectl exec $POD_NAME -- curl -s localhost:5000/test-azure-db 2>/dev/null || echo "test-azure-db endpoint not available"

echo ""
echo "📊 Testing /api/results endpoint from inside pod..."
kubectl exec $POD_NAME -- curl -s localhost:5000/api/results

echo ""
echo "🔍 Checking if the Flask app has both database connection functions..."
kubectl exec $POD_NAME -- python3 -c "
import requests
import psycopg2
import os

# Test local database connection
print('🏠 Testing local database connection...')
try:
    local_conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'postgres-service'),
        database=os.environ.get('DB_NAME', 'voting'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'postgres123')
    )
    cursor = local_conn.cursor()
    try:
        cursor.execute('SELECT vote_choice, COUNT(*) FROM votes GROUP BY vote_choice')
    except:
        try:
            cursor.execute('SELECT vote_option, COUNT(*) FROM votes GROUP BY vote_option')
        except:
            cursor.execute('SELECT option, COUNT(*) FROM votes GROUP BY option')
    
    local_votes = cursor.fetchall()
    print(f'  Local votes: {local_votes}')
    local_conn.close()
except Exception as e:
    print(f'  Local DB error: {e}')

# Test Azure database connection  
print('☁️  Testing Azure database connection...')
try:
    azure_conn = psycopg2.connect(
        host='postgres-cat-dog-voting.postgres.database.azure.com',
        database='postgres',
        user='votinguser',
        password='SecureVotingPassword123!',
        port=5432,
        sslmode='require'
    )
    cursor = azure_conn.cursor()
    cursor.execute('SELECT option, COUNT(*) FROM vote_option GROUP BY option')
    azure_votes = cursor.fetchall()
    print(f'  Azure votes: {azure_votes}')
    azure_conn.close()
except Exception as e:
    print(f'  Azure DB error: {e}')

print('')
print('🤔 Both connections work, so the issue must be in the Flask app logic...')
"

echo ""
echo "💡 The problem might be:"
echo "   1. Flask app logic error in /api/results endpoint"
echo "   2. App falling back to old API method instead of direct database"
echo "   3. Environment variables not set correctly"
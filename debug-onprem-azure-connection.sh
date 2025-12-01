# Debug script to check on-premises pod logs for Azure database connection issues

echo "🔍 Checking on-premises pod logs for Azure database connection..."
echo ""

# Get the pod name
POD_NAME=$(kubectl get pods -l app=voting-app-azure -o jsonpath='{.items[0].metadata.name}')
echo "📋 Pod name: $POD_NAME"
echo ""

# Check recent logs for any database connection attempts or errors
echo "📊 Recent pod logs:"
kubectl logs $POD_NAME --tail=20

echo ""
echo "🔍 Searching for Azure database related messages..."
kubectl logs $POD_NAME | grep -i "azure\|database\|postgres\|connection\|error" || echo "No database-related messages found"

echo ""
echo "🧪 Testing Azure database connection directly from pod..."
kubectl exec $POD_NAME -- python3 -c "
import psycopg2
import os

try:
    print('🔌 Testing Azure PostgreSQL connection...')
    conn = psycopg2.connect(
        host='postgres-cat-dog-voting.postgres.database.azure.com',
        database='postgres',
        user='votinguser',
        password='SecureVotingPassword123!',
        port=5432,
        sslmode='require',
        connect_timeout=10
    )
    print('✅ Azure PostgreSQL connection successful!')
    
    cursor = conn.cursor()
    cursor.execute('SELECT option, COUNT(*) FROM vote_option GROUP BY option;')
    counts = cursor.fetchall()
    
    print('📊 Azure vote counts from pod:')
    for option, count in counts:
        print(f'  {option}: {count}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Azure database connection failed: {e}')
"

echo ""
echo "🎯 If connection fails, the app falls back to old cached API data (1 cat, 0 dogs)"
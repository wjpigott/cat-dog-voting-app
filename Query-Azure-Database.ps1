# Query Azure PostgreSQL Database to Check Vote Counts
# This script runs a query pod to check the actual vote data in Azure

Write-Host "🔍 Checking actual vote counts in Azure PostgreSQL database..." -ForegroundColor Green

# Create a temporary pod to query the database
$queryPodYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: azure-db-query
  labels:
    app: azure-db-query
spec:
  restartPolicy: Never
  containers:
  - name: query-container
    image: python:3.9-slim
    env:
    - name: AZURE_DB_HOST
      value: "postgres-cat-dog-voting.postgres.database.azure.com"
    - name: AZURE_DB_NAME
      value: "postgres"
    - name: AZURE_DB_USER
      value: "votinguser"
    - name: AZURE_DB_PASSWORD
      value: "SecureVotingPassword123!"
    command: ["/bin/sh"]
    args:
      - -c
      - |
        pip install psycopg2-binary
        python3 -c "
        import psycopg2
        import os
        
        try:
            print('🔍 Connecting to Azure PostgreSQL...')
            conn = psycopg2.connect(
                host=os.environ['AZURE_DB_HOST'],
                database=os.environ['AZURE_DB_NAME'],
                user=os.environ['AZURE_DB_USER'],
                password=os.environ['AZURE_DB_PASSWORD'],
                port=5432,
                sslmode='require'
            )
            
            print('✅ Connected successfully!')
            cursor = conn.cursor()
            
            # Check what tables exist
            cursor.execute(\"\"\"
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            \"\"\")
            tables = cursor.fetchall()
            print(f'📋 Available tables: {[t[0] for t in tables]}')
            
            if tables:
                # Check vote_option table
                try:
                    cursor.execute('SELECT option, COUNT(*) FROM vote_option GROUP BY option ORDER BY option;')
                    vote_counts = cursor.fetchall()
                    
                    print('\\n📊 Current Azure vote counts:')
                    total = 0
                    for option, count in vote_counts:
                        print(f'  {option}: {count} votes')
                        total += count
                    print(f'\\n🎯 Total Azure votes: {total}')
                    
                    # Show some sample data
                    cursor.execute('SELECT id, option, timestamp FROM vote_option ORDER BY id LIMIT 10;')
                    samples = cursor.fetchall()
                    print('\\n📝 Sample data:')
                    for row in samples:
                        print(f'  ID: {row[0]}, Option: {row[1]}, Time: {row[2]}')
                        
                except Exception as e:
                    print(f'❌ Error querying vote_option: {e}')
                    
                    # Try to see table structure
                    cursor.execute(\"\"\"
                        SELECT column_name, data_type 
                        FROM information_schema.columns 
                        WHERE table_name = 'vote_option';
                    \"\"\")
                    columns = cursor.fetchall()
                    print(f'vote_option columns: {columns}')
            else:
                print('❌ No tables found!')
                
            conn.close()
            
        except Exception as e:
            print(f'❌ Error: {e}')
        "
        
        echo "Query completed."
"@

# Save and apply the query pod
$queryPodYaml | Out-File -FilePath "azure-db-query.yaml" -Encoding utf8

Write-Host "📝 Creating query pod..." -ForegroundColor Yellow
kubectl apply -f azure-db-query.yaml

Write-Host "⏳ Waiting for query to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host "📊 Query results:" -ForegroundColor Green
kubectl logs azure-db-query

Write-Host "🧹 Cleaning up query pod..." -ForegroundColor Yellow
kubectl delete pod azure-db-query

Remove-Item "azure-db-query.yaml"
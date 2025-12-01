# Update On-Premises K3s Deployment with Direct Azure Database Connection
# This script should be run on your on-premises K3s cluster

Write-Host "🎯 Updating on-premises K3s voting app with direct Azure database connection..." -ForegroundColor Green

# Create the deployment YAML for on-premises with Azure DB connection
$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-azure
  labels:
    app: voting-app-azure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-app-azure
  template:
    metadata:
      labels:
        app: voting-app-azure
    spec:
      containers:
      - name: voting-app
        image: python:3.9-slim
        ports:
        - containerPort: 5000
        env:
        - name: DB_HOST
          value: "postgres-service"
        - name: DB_NAME
          value: "voting"
        - name: DB_USER
          value: "postgres"
        - name: DB_PASSWORD
          value: "postgres123"
        - name: AZURE_DB_HOST
          value: "postgres-cat-dog-voting.postgres.database.azure.com"
        - name: AZURE_DB_NAME
          value: "postgres"
        - name: AZURE_DB_USER
          value: "votinguser"
        - name: AZURE_DB_PASSWORD
          value: "SecureVotingPassword123!"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        command: ["/bin/sh"]
        args:
          - -c
          - |
            pip install flask psycopg2-binary requests
            cat > /app.py << 'EOF'
            from flask import Flask, render_template, request, jsonify
            import psycopg2
            import os
            import logging
            from datetime import datetime

            logging.basicConfig(level=logging.INFO)
            logger = logging.getLogger(__name__)

            app = Flask(__name__)

            def get_local_db_connection():
                try:
                    return psycopg2.connect(
                        host=os.environ['DB_HOST'],
                        database=os.environ['DB_NAME'],
                        user=os.environ['DB_USER'],
                        password=os.environ['DB_PASSWORD']
                    )
                except Exception as e:
                    logger.error(f"Local DB connection error: {e}")
                    return None

            def get_azure_db_connection():
                try:
                    conn = psycopg2.connect(
                        host=os.environ['AZURE_DB_HOST'],
                        database=os.environ['AZURE_DB_NAME'],
                        user=os.environ['AZURE_DB_USER'],
                        password=os.environ['AZURE_DB_PASSWORD'],
                        port=5432,
                        sslmode='require'
                    )
                    logger.info("✅ Azure PostgreSQL connection successful!")
                    return conn
                except Exception as e:
                    logger.error(f"Azure DB connection error: {e}")
                    return None

            def get_azure_votes_direct():
                conn = get_azure_db_connection()
                votes = {'cat': 0, 'dog': 0}

                if conn:
                    try:
                        with conn.cursor() as cursor:
                            cursor.execute("SELECT option, COUNT(*) FROM vote_option GROUP BY option")
                            for vote_type, count in cursor.fetchall():
                                if vote_type and vote_type.lower() in ['cat', 'cats']:
                                    votes['cat'] = count
                                elif vote_type and vote_type.lower() in ['dog', 'dogs']:
                                    votes['dog'] = count
                        conn.close()
                        logger.info(f"✅ Direct Azure DB votes: {votes}")
                    except Exception as e:
                        logger.error(f"Azure DB query error: {e}")
                        conn.close()

                return votes

            def get_local_votes():
                conn = get_local_db_connection()
                votes = {'cat': 0, 'dog': 0}

                if conn:
                    try:
                        with conn.cursor() as cursor:
                            try:
                                cursor.execute("SELECT vote_choice, COUNT(*) FROM votes GROUP BY vote_choice")
                            except:
                                cursor.execute("SELECT vote_option, COUNT(*) FROM votes GROUP BY vote_option")
                            
                            for vote_type, count in cursor.fetchall():
                                if vote_type and vote_type.lower() in ['cat', 'cats']:
                                    votes['cat'] = count
                                elif vote_type and vote_type.lower() in ['dog', 'dogs']:
                                    votes['dog'] = count
                        conn.close()
                    except Exception as e:
                        logger.error(f"Local DB error: {e}")

                return votes

            @app.route('/api/results')
            def get_results():
                local_votes = get_local_votes()
                azure_votes = get_azure_votes_direct()
                
                total_cat = azure_votes['cat'] + local_votes['cat']
                total_dog = azure_votes['dog'] + local_votes['dog']
                grand_total = total_cat + total_dog
                
                cat_percentage = (total_cat / grand_total * 100) if grand_total > 0 else 0
                dog_percentage = (total_dog / grand_total * 100) if grand_total > 0 else 0

                return jsonify({
                    'environment': 'onprem',
                    'timestamp': datetime.now().isoformat(),
                    'votes': {
                        'cat': {
                            'azure': azure_votes['cat'],
                            'onprem': local_votes['cat'],
                            'total': total_cat,
                            'percentage': round(cat_percentage, 2)
                        },
                        'dog': {
                            'azure': azure_votes['dog'],
                            'onprem': local_votes['dog'], 
                            'total': total_dog,
                            'percentage': round(dog_percentage, 2)
                        }
                    }
                })

            @app.route('/test-azure-db')
            def test_azure_db():
                try:
                    azure_votes = get_azure_votes_direct()
                    return jsonify({
                        'success': True,
                        'azure_votes': azure_votes,
                        'method': 'direct_database_connection'
                    })
                except Exception as e:
                    return jsonify({
                        'success': False,
                        'error': str(e),
                        'method': 'direct_database_connection'
                    })

            @app.route('/health')
            def health():
                return jsonify({
                    'status': 'healthy',
                    'mode': 'direct-azure-db',
                    'azure_db_host': os.environ.get('AZURE_DB_HOST')
                })

            @app.route('/vote', methods=['POST'])
            def vote():
                vote_data = request.get_json()
                if not vote_data or 'vote' not in vote_data:
                    return jsonify({'error': 'Invalid vote data'}), 400

                vote_choice = vote_data['vote'].lower()
                if vote_choice not in ['cat', 'dog']:
                    return jsonify({'error': 'Invalid vote choice'}), 400

                conn = get_local_db_connection()
                if conn:
                    try:
                        with conn.cursor() as cursor:
                            try:
                                cursor.execute("INSERT INTO votes (vote_choice) VALUES (%s)", (vote_choice,))
                            except:
                                cursor.execute("INSERT INTO votes (vote_option) VALUES (%s)", (vote_choice,))
                        conn.commit()
                        conn.close()
                        return jsonify({'success': True, 'vote': vote_choice})
                    except Exception as e:
                        logger.error(f"Vote insert error: {e}")
                        return jsonify({'error': str(e)}), 500

                return jsonify({'error': 'Database connection failed'}), 500

            @app.route('/')
            def index():
                return '''<!DOCTYPE html><html><head><title>🌐 Direct Azure DB Voting</title></head><body><h1>On-Premises Voting App with Direct Azure DB Access</h1><p>API: /api/results | Test: /test-azure-db</p></body></html>'''

            if __name__ == '__main__':
                logger.info("🎯 Starting on-premises voting app with direct Azure database connection...")
                logger.info("🌐 Azure DB: postgres-cat-dog-voting.postgres.database.azure.com")
                app.run(host='0.0.0.0', port=5000, debug=False)
            EOF

            python /app.py
"@

# Save the deployment to a file
$deploymentYaml | Out-File -FilePath "onprem-azure-direct-deployment.yaml" -Encoding utf8

Write-Host "📝 Deployment YAML created: onprem-azure-direct-deployment.yaml" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 To apply this to your on-premises K3s cluster, run these commands:" -ForegroundColor Green
Write-Host ""
Write-Host "   # On your on-premises K3s cluster machine:" -ForegroundColor Cyan
Write-Host "   kubectl apply -f onprem-azure-direct-deployment.yaml" -ForegroundColor White
Write-Host ""
Write-Host "   # Wait for the pod to restart (1-2 minutes), then test:" -ForegroundColor Cyan
Write-Host "   curl http://66.242.207.21:31514/api/results" -ForegroundColor White
Write-Host ""
Write-Host "✅ This should show Azure votes: 4 cats, 3 dogs" -ForegroundColor Green
#!/bin/bash
# Direct deployment command for the fixed on-premises app

echo "🚀 Deploying fixed on-premises app with accurate Azure API calls..."

kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-onprem-fixed
  labels:
    app: voting-app-onprem-fixed
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-app-onprem-fixed
  template:
    metadata:
      labels:
        app: voting-app-onprem-fixed
    spec:
      containers:
      - name: voting-app
        image: python:3.9-slim
        ports:
        - containerPort: 5000
        env:
        - name: VOTE_SOURCE
          value: "onprem"
        - name: DB_HOST
          value: "postgres-service"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "voting_app"
        - name: DB_USER
          value: "votinguser"
        - name: DB_PASSWORD
          value: "secure_password_123"
        - name: AZURE_API_URL
          value: "http://172.169.25.121"
        command: ["/bin/bash", "-c"]
        args:
          - |
            echo "🚀 Installing dependencies..."
            pip install flask psycopg2-binary requests
            mkdir -p /app/templates
            
            cat > /app/app.py << 'PYEOF'
            from flask import Flask, render_template, request, jsonify
            import psycopg2
            import os
            import requests
            import json

            app = Flask(__name__)

            DB_CONFIG = {
                'host': os.getenv('DB_HOST', 'postgres-service'),
                'port': int(os.getenv('DB_PORT', '5432')),
                'database': os.getenv('DB_NAME', 'voting_app'),
                'user': os.getenv('DB_USER', 'votinguser'),
                'password': os.getenv('DB_PASSWORD', 'secure_password_123')
            }

            ENVIRONMENT = 'onprem'
            AZURE_API_URL = os.getenv('AZURE_API_URL', 'http://172.169.25.121')

            def get_db_connection():
                try:
                    return psycopg2.connect(**DB_CONFIG)
                except Exception as e:
                    print(f"DB error: {e}")
                    return None

            def get_local_votes():
                conn = get_db_connection()
                if not conn:
                    return {'cat': 0, 'dog': 0}
                try:
                    cursor = conn.cursor()
                    try:
                        cursor.execute("SELECT vote_choice, COUNT(*) FROM votes GROUP BY vote_choice")
                    except:
                        cursor.execute("SELECT vote_option, COUNT(*) FROM votes GROUP BY vote_option")
                    results = cursor.fetchall()
                    votes = {'cat': 0, 'dog': 0}
                    for choice, count in results:
                        votes[choice] = count
                    cursor.close()
                    conn.close()
                    return votes
                except Exception as e:
                    print(f"Local votes error: {e}")
                    return {'cat': 0, 'dog': 0}

            def get_azure_votes():
                try:
                    url = f"{AZURE_API_URL}/api/local-results"
                    print(f"🔗 Calling: {url}")
                    response = requests.get(url, timeout=10)
                    if response.status_code == 200:
                        data = response.json()
                        votes = data.get('votes', {'cat': 0, 'dog': 0})
                        print(f"✅ Azure votes: {votes}")
                        return votes
                    else:
                        print(f"❌ Azure API status: {response.status_code}")
                        return {'cat': 0, 'dog': 0}
                except Exception as e:
                    print(f"❌ Azure API error: {e}")
                    return {'cat': 0, 'dog': 0}

            @app.route('/')
            def index():
                local = get_local_votes()
                azure = get_azure_votes()
                total_cat = local.get('cat', 0) + azure.get('cat', 0)
                total_dog = local.get('dog', 0) + azure.get('dog', 0)
                return render_template('voting.html', 
                                     cat_votes=total_cat, dog_votes=total_dog,
                                     total_votes=total_cat + total_dog,
                                     azure_cat_votes=azure.get('cat', 0),
                                     azure_dog_votes=azure.get('dog', 0),
                                     onprem_cat_votes=local.get('cat', 0),
                                     onprem_dog_votes=local.get('dog', 0))

            @app.route('/api/results')
            def api_results():
                local = get_local_votes()
                azure = get_azure_votes()
                total_cat = local.get('cat', 0) + azure.get('cat', 0)
                total_dog = local.get('dog', 0) + azure.get('dog', 0)
                return jsonify({
                    'votes': {'cat': total_cat, 'dog': total_dog},
                    'azure_votes': azure, 'onprem_votes': local,
                    'total_votes': total_cat + total_dog,
                    'environment': ENVIRONMENT
                })

            @app.route('/test-azure')
            def test_azure():
                return jsonify({
                    'azure_api_url': f"{AZURE_API_URL}/api/local-results",
                    'azure_votes': get_azure_votes()
                })

            if __name__ == '__main__':
                print(f"🎯 Fixed on-premises app starting...")
                app.run(host='0.0.0.0', port=5000, debug=True)
            PYEOF
            
            cat > /app/templates/voting.html << 'HTMLEOF'
            <!DOCTYPE html>
            <html><head><title>Fixed On-Premises</title>
            <style>
            body{font-family:Arial;background:linear-gradient(135deg,#2d5a27,#4caf50);color:white;text-align:center;padding:50px}
            .card{background:rgba(255,255,255,0.1);padding:30px;border-radius:15px;margin:20px}
            </style></head><body>
            <h1>🏠 Fixed On-Premises Voting</h1>
            <div class="card">
            <h2>🐱 Cats: {{ cat_votes }}</h2>
            <h2>🐶 Dogs: {{ dog_votes }}</h2>
            <h3>Total: {{ total_votes }}</h3>
            </div>
            <div class="card">
            <h3>Cross-Environment Data</h3>
            <p>☁️ Azure: {{ azure_cat_votes }} cats, {{ azure_dog_votes }} dogs</p>
            <p>🏠 On-Premises: {{ onprem_cat_votes }} cats, {{ onprem_dog_votes }} dogs</p>
            </div>
            <p><a href="/test-azure" style="color:yellow">Test Azure API</a></p>
            </body></html>
            HTMLEOF
            
            cd /app && python app.py
        resources:
          requests: { memory: "128Mi", cpu: "100m" }
          limits: { memory: "256Mi", cpu: "200m" }
---
apiVersion: v1
kind: Service
metadata:
  name: voting-app-onprem-fixed-service
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 5000
    nodePort: 31515
  selector:
    app: voting-app-onprem-fixed
EOF

echo "✅ Fixed on-premises app deployed!"
echo "🌐 Test URLs:"
echo "  Main app: http://66.242.207.21:31515"
echo "  API test: http://66.242.207.21:31515/test-azure"
echo "  Results: http://66.242.207.21:31515/api/results"
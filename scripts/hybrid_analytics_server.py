#!/usr/bin/env python3
"""
Cross-Environment Analytics Web API
Provides REST endpoint for hybrid cloud voting analytics
"""

from flask import Flask, jsonify, render_template_string
import psycopg2
import json
from datetime import datetime
import os

app = Flask(__name__)

class HybridAnalytics:
    def __init__(self):
        # Database configurations
        self.databases = {
            'onprem': {
                'host': os.getenv('ONPREM_DB_HOST', '66.242.207.21'),
                'port': int(os.getenv('ONPREM_DB_PORT', 5432)),
                'database': 'voting_app',
                'user': 'votinguser',
                'password': 'secure_password_123'
            },
            'azure': {
                'host': os.getenv('AZURE_DB_HOST', 'postgres-cat-dog-voting.postgres.database.azure.com'),
                'port': int(os.getenv('AZURE_DB_PORT', 5432)),
                'database': 'voting_app',
                'user': 'votinguser',
                'password': 'SecureVotingPassword123!'
            }
        }

    def get_environment_data(self, env_name: str) -> dict:
        """Get data from a specific environment database"""
        config = self.databases[env_name]
        
        try:
            conn = psycopg2.connect(**config)
            cursor = conn.cursor()
            
            # Get vote counts
            cursor.execute("SELECT vote_option, COUNT(*) FROM votes GROUP BY vote_option")
            vote_counts = {row[0]: row[1] for row in cursor.fetchall()}
            
            # Get total votes
            cursor.execute("SELECT COUNT(*) FROM votes")
            total_votes = cursor.fetchone()[0]
            
            # Get votes by source
            cursor.execute("SELECT source, COUNT(*) FROM votes GROUP BY source")
            by_source = {row[0]: row[1] for row in cursor.fetchall()}
            
            conn.close()
            
            return {
                'status': 'healthy',
                'vote_counts': vote_counts,
                'total_votes': total_votes,
                'by_source': by_source,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }

analytics = HybridAnalytics()

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'hybrid-analytics'})

@app.route('/analytics')
def get_analytics():
    """Get cross-environment analytics"""
    
    # Get data from both environments
    onprem_data = analytics.get_environment_data('onprem')
    azure_data = analytics.get_environment_data('azure')
    
    # Calculate totals
    total_cats = 0
    total_dogs = 0
    total_votes = 0
    
    for data in [onprem_data, azure_data]:
        if data['status'] == 'healthy':
            total_cats += data['vote_counts'].get('cat', 0)
            total_dogs += data['vote_counts'].get('dog', 0)
            total_votes += data['total_votes']
    
    return jsonify({
        'summary': {
            'total_votes': total_votes,
            'cats': total_cats,
            'dogs': total_dogs,
            'cat_percentage': round((total_cats / max(total_votes, 1)) * 100, 1),
            'dog_percentage': round((total_dogs / max(total_votes, 1)) * 100, 1)
        },
        'environments': {
            'onprem': onprem_data,
            'azure': azure_data
        },
        'hybrid_status': {
            'onprem_healthy': onprem_data['status'] == 'healthy',
            'azure_healthy': azure_data['status'] == 'healthy'
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/')
def dashboard():
    """Analytics dashboard"""
    html_template = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hybrid Cloud Voting Analytics</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
            .container { max-width: 1200px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
            .stats { display: flex; gap: 20px; margin-bottom: 20px; }
            .stat-box { background: white; padding: 20px; border-radius: 10px; flex: 1; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
            .env-section { background: white; margin: 10px 0; padding: 20px; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
            .healthy { color: #27ae60; }
            .error { color: #e74c3c; }
            .refresh-btn { background: #3498db; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
        </style>
        <script>
            function refreshData() {
                fetch('/analytics')
                    .then(response => response.json())
                    .then(data => {
                        document.getElementById('data').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                        updateSummary(data);
                    });
            }
            
            function updateSummary(data) {
                document.getElementById('total-votes').textContent = data.summary.total_votes;
                document.getElementById('cat-votes').textContent = data.summary.cats;
                document.getElementById('dog-votes').textContent = data.summary.dogs;
                document.getElementById('cat-pct').textContent = data.summary.cat_percentage + '%';
                document.getElementById('dog-pct').textContent = data.summary.dog_percentage + '%';
                
                document.getElementById('onprem-status').textContent = data.hybrid_status.onprem_healthy ? 'Healthy' : 'Error';
                document.getElementById('onprem-status').className = data.hybrid_status.onprem_healthy ? 'healthy' : 'error';
                document.getElementById('azure-status').textContent = data.hybrid_status.azure_healthy ? 'Healthy' : 'Error';
                document.getElementById('azure-status').className = data.hybrid_status.azure_healthy ? 'healthy' : 'error';
            }
            
            setInterval(refreshData, 5000); // Auto-refresh every 5 seconds
            window.onload = refreshData;
        </script>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🐱🐶 Hybrid Cloud Voting Analytics</h1>
                <p>Real-time analytics across Azure AKS and On-premises environments</p>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <h3>Total Votes</h3>
                    <h2 id="total-votes">0</h2>
                </div>
                <div class="stat-box">
                    <h3>🐱 Cats</h3>
                    <h2 id="cat-votes">0</h2>
                    <p id="cat-pct">0%</p>
                </div>
                <div class="stat-box">
                    <h3>🐶 Dogs</h3>
                    <h2 id="dog-votes">0</h2>
                    <p id="dog-pct">0%</p>
                </div>
            </div>
            
            <div class="env-section">
                <h3>Environment Health</h3>
                <p>On-Premises: <span id="onprem-status" class="healthy">Healthy</span></p>
                <p>Azure Cloud: <span id="azure-status" class="error">Error</span></p>
            </div>
            
            <button class="refresh-btn" onclick="refreshData()">Refresh Data</button>
            
            <div class="env-section">
                <h3>Raw Analytics Data</h3>
                <div id="data">Loading...</div>
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(html_template)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
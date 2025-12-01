import os
import json
import psycopg2
import requests
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

def get_azure_db_connection():
    """Direct connection to Azure PostgreSQL database"""
    try:
        return psycopg2.connect(
            host='postgres-cat-dog-voting.postgres.database.azure.com',
            port=5432,
            database='postgres',
            user='adminuser',
            password='ComplexPassword123!',
            sslmode='require'
        )
    except Exception as e:
        print(f"❌ Error connecting to Azure PostgreSQL: {e}")
        return None

def get_onprem_votes():
    """Get votes from on-premises environment via API"""
    try:
        # Try to get on-premises votes from the API
        response = requests.get('http://66.242.207.21:31514/api/results', timeout=5)
        if response.status_code == 200:
            data = response.json()
            return data.get('onprem_votes', {'cat': 0, 'dog': 0})
        else:
            print(f"⚠️ On-premises API returned status {response.status_code}")
            return {'cat': 0, 'dog': 0}
    except Exception as e:
        print(f"⚠️ Could not fetch on-premises votes: {e}")
        return {'cat': 0, 'dog': 0}

def get_azure_votes():
    """Get votes from Azure PostgreSQL database"""
    try:
        azure_conn = get_azure_db_connection()
        if not azure_conn:
            return {'cat': 0, 'dog': 0}
        
        cursor = azure_conn.cursor()
        cursor.execute("SELECT vote_option, vote_count FROM vote_option ORDER BY vote_option")
        rows = cursor.fetchall()
        
        votes = {'cat': 0, 'dog': 0}
        print("📊 Azure PostgreSQL rows:")
        for option, count in rows:
            print(f"  Azure row: option='{option}', count={count}")
            if option and option.lower() in ['cat', 'cats']:
                votes['cat'] = count
            elif option and option.lower() in ['dog', 'dogs']:
                votes['dog'] = count
        
        cursor.close()
        azure_conn.close()
        print(f"✅ Azure votes: {votes}")
        return votes
        
    except Exception as e:
        print(f"❌ Error getting Azure votes: {e}")
        return {'cat': 0, 'dog': 0}

def save_vote_to_azure(vote_option):
    """Save a vote to Azure PostgreSQL database"""
    try:
        azure_conn = get_azure_db_connection()
        if not azure_conn:
            return False
        
        cursor = azure_conn.cursor()
        
        # Update the vote count
        cursor.execute("""
            UPDATE vote_option 
            SET vote_count = vote_count + 1 
            WHERE LOWER(vote_option) = LOWER(%s)
        """, (vote_option,))
        
        azure_conn.commit()
        cursor.close()
        azure_conn.close()
        print(f"✅ Saved vote for {vote_option} to Azure PostgreSQL")
        return True
        
    except Exception as e:
        print(f"❌ Error saving vote to Azure: {e}")
        return False

@app.route('/api/results')
def api_results():
    """API endpoint for getting cross-environment vote results"""
    
    # Get Azure votes directly from Azure PostgreSQL
    azure_votes = get_azure_votes()
    
    # Get on-premises votes from API
    onprem_votes = get_onprem_votes()
    
    # Calculate totals
    total_cat = azure_votes['cat'] + onprem_votes['cat']
    total_dog = azure_votes['dog'] + onprem_votes['dog']
    
    result = {
        'environment': 'azure',
        'azure_votes': azure_votes,
        'onprem_votes': onprem_votes,
        'votes': {'cat': total_cat, 'dog': total_dog},
        'total_votes': total_cat + total_dog
    }
    
    print(f"📊 Azure API result: {result}")
    return jsonify(result)

@app.route('/vote', methods=['POST'])
def vote():
    """Handle vote submission"""
    try:
        data = request.get_json()
        vote_option = data.get('vote')
        
        if vote_option not in ['cat', 'dog']:
            return jsonify({'status': 'error', 'message': 'Invalid vote option'}), 400
        
        # Save vote to Azure PostgreSQL
        success = save_vote_to_azure(vote_option)
        
        if success:
            print(f"✅ Vote for {vote_option} saved to Azure database")
            return jsonify({'status': 'success', 'vote': vote_option})
        else:
            return jsonify({'status': 'error', 'message': 'Failed to save vote'}), 500
            
    except Exception as e:
        print(f"❌ Error in vote endpoint: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        # Test database connection
        azure_conn = get_azure_db_connection()
        if azure_conn:
            azure_conn.close()
            return jsonify({'status': 'healthy', 'database': 'connected'})
        else:
            return jsonify({'status': 'unhealthy', 'database': 'disconnected'}), 500
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/')
def index():
    """Main voting interface with cross-environment display"""
    
    # Get current vote data
    azure_votes = get_azure_votes()
    onprem_votes = get_onprem_votes()
    total_cat = azure_votes['cat'] + onprem_votes['cat']
    total_dog = azure_votes['dog'] + onprem_votes['dog']
    total_votes = total_cat + total_dog
    
    html_template = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>🐱🐶 Cross-Environment Voting - AZURE</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                margin: 0;
                padding: 40px;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            .container {
                background: white;
                border-radius: 20px;
                padding: 40px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                max-width: 800px;
                width: 100%;
            }
            .header {
                background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
                color: white;
                padding: 30px;
                border-radius: 15px;
                text-align: center;
                margin-bottom: 40px;
            }
            .header h1 {
                margin: 0;
                font-size: 2.5em;
                font-weight: 700;
            }
            .subtitle {
                margin: 10px 0 0 0;
                font-size: 1.1em;
                opacity: 0.9;
            }
            .voting-area {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 30px;
                margin-bottom: 40px;
            }
            .vote-option {
                background: #f8f9fa;
                border: 3px solid #e9ecef;
                border-radius: 15px;
                padding: 40px 20px;
                text-align: center;
                cursor: pointer;
                transition: all 0.3s ease;
            }
            .vote-option:hover {
                transform: translateY(-5px);
                box-shadow: 0 15px 30px rgba(0,0,0,0.2);
            }
            .cat-option:hover {
                border-color: #ff6b6b;
                background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
            }
            .dog-option:hover {
                border-color: #4ecdc4;
                background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
            }
            .vote-emoji {
                font-size: 4em;
                margin-bottom: 20px;
                display: block;
            }
            .vote-title {
                font-size: 2em;
                font-weight: 700;
                margin-bottom: 15px;
                color: #343a40;
            }
            .vote-count {
                font-size: 3em;
                font-weight: 800;
                color: #495057;
                margin-bottom: 15px;
            }
            .vote-button {
                background: #007bff;
                color: white;
                border: none;
                padding: 15px 30px;
                border-radius: 10px;
                font-size: 1.1em;
                font-weight: 600;
                cursor: pointer;
            }
            .results-section {
                background: #f8f9fa;
                border-radius: 15px;
                padding: 30px;
                margin-top: 30px;
            }
            .results-title {
                text-align: center;
                font-size: 1.8em;
                font-weight: 700;
                color: #495057;
                margin-bottom: 30px;
            }
            .environment-results {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
                margin-bottom: 25px;
            }
            .env-card {
                background: white;
                border-radius: 10px;
                padding: 20px;
                border-left: 5px solid #28a745;
            }
            .env-card.azure {
                border-left-color: #007bff;
            }
            .env-title {
                font-size: 1.2em;
                font-weight: 600;
                margin-bottom: 10px;
                color: #495057;
            }
            .env-votes {
                font-size: 0.9em;
                color: #6c757d;
            }
            .total-section {
                text-align: center;
                padding: 20px;
                background: white;
                border-radius: 10px;
            }
            .total-votes {
                font-size: 1.5em;
                font-weight: 700;
                color: #495057;
            }
            .refresh-btn {
                background: #17a2b8;
                color: white;
                border: none;
                padding: 12px 25px;
                border-radius: 8px;
                font-size: 1em;
                cursor: pointer;
                margin-top: 15px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🐱 🐶 Cross-Environment Voting</h1>
                <div class="subtitle">🌩️ AZURE: Updates Azure PostgreSQL Database</div>
            </div>
            
            <div class="voting-area">
                <div class="vote-option cat-option" onclick="vote('cat')">
                    <span class="vote-emoji">🐱</span>
                    <div class="vote-title">CATS</div>
                    <div class="vote-count">{{ total_cat }}</div>
                    <div class="vote-button">Click to vote!</div>
                </div>
                
                <div class="vote-option dog-option" onclick="vote('dog')">
                    <span class="vote-emoji">🐶</span>
                    <div class="vote-title">DOGS</div>
                    <div class="vote-count">{{ total_dog }}</div>
                    <div class="vote-button">Click to vote!</div>
                </div>
            </div>
            
            <div class="results-section">
                <div class="results-title">📊 Cross-Environment Results</div>
                
                <div class="environment-results">
                    <div class="env-card azure">
                        <div class="env-title">☁️ Azure Cloud</div>
                        <div class="env-votes">
                            Cats: {{ azure_cat }}<br>
                            Dogs: {{ azure_dog }}
                        </div>
                    </div>
                    
                    <div class="env-card">
                        <div class="env-title">🏠 On-Premises</div>
                        <div class="env-votes">
                            Cats: {{ onprem_cat }}<br>
                            Dogs: {{ onprem_dog }}
                        </div>
                    </div>
                </div>
                
                <div class="total-section">
                    <div class="total-votes">Total Votes: {{ total_votes }}</div>
                    <button class="refresh-btn" onclick="refreshResults()">🔄 Refresh Results</button>
                </div>
            </div>
        </div>

        <script>
            function vote(option) {
                fetch('/vote', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({vote: option})
                })
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'success') {
                        location.reload();
                    } else {
                        alert('Error: ' + (data.message || 'Failed to save vote'));
                    }
                })
                .catch(error => {
                    alert('Error submitting vote: ' + error);
                });
            }
            
            function refreshResults() {
                location.reload();
            }
        </script>
    </body>
    </html>
    '''
    
    return render_template_string(
        html_template,
        total_cat=total_cat,
        total_dog=total_dog,
        azure_cat=azure_votes['cat'],
        azure_dog=azure_votes['dog'],
        onprem_cat=onprem_votes['cat'],
        onprem_dog=onprem_votes['dog'],
        total_votes=total_votes
    )

if __name__ == '__main__':
    print("🚀 Starting Azure cross-environment voting app...")
    print("🔗 Connects to: Azure PostgreSQL + On-premises API")
    print("💾 Saves votes to: Azure PostgreSQL Database")
    app.run(host='0.0.0.0', port=5000)
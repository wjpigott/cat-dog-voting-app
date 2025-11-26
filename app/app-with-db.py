from flask import Flask, render_template, request, jsonify, redirect, url_for
import psycopg2
import os
import json
from datetime import datetime
import socket

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres-service'),
    'port': int(os.getenv('DB_PORT', '5432')),
    'database': os.getenv('DB_NAME', 'voting_app'),
    'user': os.getenv('DB_USER', 'votinguser'),
    'password': os.getenv('DB_PASSWORD', 'secure_password_123')
}

# Determine environment (azure vs onprem)
ENVIRONMENT = os.getenv('VOTE_SOURCE', 'onprem')

def get_db_connection():
    try:
        return psycopg2.connect(**DB_CONFIG)
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def init_database():
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Create table if it doesn't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS votes (
                id SERIAL PRIMARY KEY,
                vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('cat', 'dog')),
                vote_source VARCHAR(20) NOT NULL CHECK (vote_source IN ('azure', 'onprem')),
                timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                ip_address INET,
                user_agent TEXT,
                session_id VARCHAR(255)
            )
        ''')
        
        # Create view
        cursor.execute('''
            CREATE OR REPLACE VIEW vote_summary AS
            SELECT 
                vote_choice,
                COUNT(*) as total_votes,
                COUNT(CASE WHEN vote_source = 'azure' THEN 1 END) as azure_votes,
                COUNT(CASE WHEN vote_source = 'onprem' THEN 1 END) as onprem_votes,
                ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM votes), 2) as percentage
            FROM votes 
            GROUP BY vote_choice
        ''')
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"Database initialization error: {e}")
        return False

@app.route('/')
def index():
    conn = get_db_connection()
    if not conn:
        return render_template('voting.html', 
                             cat_votes=0, 
                             dog_votes=0, 
                             total_votes=0,
                             environment=ENVIRONMENT,
                             error="Database connection failed")
    
    try:
        cursor = conn.cursor()
        
        # Get vote summary
        cursor.execute("SELECT * FROM vote_summary ORDER BY vote_choice")
        results = cursor.fetchall()
        
        votes = {'cat': 0, 'dog': 0}
        azure_votes = {'cat': 0, 'dog': 0}
        onprem_votes = {'cat': 0, 'dog': 0}
        
        for row in results:
            choice, total, azure, onprem, percentage = row
            votes[choice] = total
            azure_votes[choice] = azure
            onprem_votes[choice] = onprem
        
        total_votes = sum(votes.values())
        
        cursor.close()
        conn.close()
        
        return render_template('voting.html', 
                             cat_votes=votes['cat'],
                             dog_votes=votes['dog'],
                             total_votes=total_votes,
                             environment=ENVIRONMENT,
                             azure_cat=azure_votes['cat'],
                             azure_dog=azure_votes['dog'],
                             onprem_cat=onprem_votes['cat'],
                             onprem_dog=onprem_votes['dog'])
        
    except Exception as e:
        print(f"Query error: {e}")
        return render_template('voting.html', 
                             cat_votes=0, 
                             dog_votes=0, 
                             total_votes=0,
                             environment=ENVIRONMENT,
                             error=str(e))

@app.route('/vote', methods=['POST'])
def vote():
    choice = request.form.get('vote')
    
    if choice not in ['cat', 'dog']:
        return redirect(url_for('index'))
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO votes (vote_choice, vote_source, ip_address, user_agent) VALUES (%s, %s, %s, %s)",
            (choice, ENVIRONMENT, request.remote_addr, request.headers.get('User-Agent', ''))
        )
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return redirect(url_for('index'))
        
    except Exception as e:
        print(f"Vote error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({
            'status': 'healthy', 
            'environment': ENVIRONMENT,
            'database': 'connected'
        })
    else:
        return jsonify({
            'status': 'unhealthy', 
            'environment': ENVIRONMENT,
            'database': 'disconnected'
        }), 500

@app.route('/results')
def results():
    # Web interface endpoint - same as api_results but without /api prefix
    return api_results()

@app.route('/api/results')
def api_results():
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM vote_summary ORDER BY vote_choice")
        results = cursor.fetchall()
        
        data = {}
        for row in results:
            choice, total, azure, onprem, percentage = row
            data[choice] = {
                'total': total,
                'azure': azure,
                'onprem': onprem,
                'percentage': float(percentage) if percentage else 0
            }
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'votes': data,
            'environment': ENVIRONMENT,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print(f"🚀 Starting Voting App (Environment: {ENVIRONMENT})")
    
    # Initialize database
    if init_database():
        print("✅ Database initialized successfully")
    else:
        print("⚠️ Database initialization failed - app may not work properly")
    
    app.run(host='0.0.0.0', port=5000, debug=True)

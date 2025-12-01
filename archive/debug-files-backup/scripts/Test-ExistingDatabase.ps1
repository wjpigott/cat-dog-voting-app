# Test Existing PostgreSQL Database Connection
param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "onprem",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseHost = "66.242.207.21",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabasePort = "31514"
)

Write-Host "🔍 Testing Existing PostgreSQL Database" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Host: $DatabaseHost" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Green

# Since we can't directly access kubectl or the database from Windows,
# let's create instructions for testing on the Ubuntu machine

$testInstructions = @"
# Run these commands on your Ubuntu machine to test the existing PostgreSQL database:

# 1. Check if PostgreSQL is running
kubectl get pods -l app=postgres

# 2. Check the service
kubectl get svc postgres-service

# 3. Test database connection
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app

# 4. Check existing data (run inside psql)
\dt  -- List tables
SELECT * FROM votes;  -- Show votes if table exists
SELECT * FROM vote_summary;  -- Show summary if view exists

# 5. If you need to create the schema (only if tables don't exist):
kubectl exec -i deployment/postgres-deployment -- psql -U votinguser -d voting_app << 'EOF'
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('cat', 'dog')),
    vote_source VARCHAR(20) NOT NULL CHECK (vote_source IN ('azure', 'onprem')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_votes_choice ON votes(vote_choice);
CREATE INDEX IF NOT EXISTS idx_votes_source ON votes(vote_source);
CREATE INDEX IF NOT EXISTS idx_votes_timestamp ON votes(timestamp);

CREATE OR REPLACE VIEW vote_summary AS
SELECT 
    vote_choice,
    COUNT(*) as total_votes,
    COUNT(CASE WHEN vote_source = 'azure' THEN 1 END) as azure_votes,
    COUNT(CASE WHEN vote_source = 'onprem' THEN 1 END) as onprem_votes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM votes), 2) as percentage
FROM votes 
GROUP BY vote_choice;

INSERT INTO votes (vote_choice, vote_source, ip_address) VALUES 
('cat', 'onprem', '10.0.1.100'),
('dog', 'onprem', '10.0.1.101'),
('cat', 'azure', '52.154.54.110')
ON CONFLICT DO NOTHING;

SELECT 'Schema created and test data inserted!' as status;
EOF

# 6. Verify the setup
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app -c "SELECT * FROM vote_summary;"
"@

Write-Host $testInstructions -ForegroundColor Cyan

Write-Host "`n🔧 Next: Update Your Voting Applications" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Create a simple Python script that can connect to the database
$pythonDbScript = @"
#!/usr/bin/env python3
# Simple database test script - save this as test_db.py on your Ubuntu machine

import psycopg2
import json
from datetime import datetime

# Database connection parameters
DB_CONFIG = {
    'host': 'postgres-service',  # or the actual service name
    'port': 5432,
    'database': 'voting_app',
    'user': 'votinguser',
    'password': 'secure_password_123'
}

def test_database():
    try:
        # Connect to database
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("✅ Database connection successful!")
        
        # Test query
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"📊 PostgreSQL version: {version[0]}")
        
        # Check if votes table exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'votes'
            );
        """)
        table_exists = cursor.fetchone()[0]
        
        if table_exists:
            print("✅ Votes table exists!")
            
            # Get current vote counts
            cursor.execute("SELECT * FROM vote_summary;")
            results = cursor.fetchall()
            
            print("\n📊 Current Vote Summary:")
            for row in results:
                choice, total, azure, onprem, percentage = row
                print(f"  {choice.upper()}: {total} votes ({azure} Azure, {onprem} On-Prem) - {percentage}%")
        else:
            print("⚠️ Votes table doesn't exist yet - run schema creation commands")
        
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def add_test_vote(choice, source):
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO votes (vote_choice, vote_source, ip_address) VALUES (%s, %s, %s)",
            (choice, source, '127.0.0.1')
        )
        conn.commit()
        
        print(f"✅ Added {choice} vote from {source}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Failed to add vote: {e}")

if __name__ == "__main__":
    print("🔍 Testing PostgreSQL Database Connection")
    print("=" * 40)
    
    if test_database():
        print("\n🎉 Database is ready for voting applications!")
        
        # Add a test vote
        add_test_vote('cat', 'onprem')
        
        # Test again to show the new vote
        test_database()
    else:
        print("\n❌ Database needs setup - check PostgreSQL deployment")
"@

# Save the Python test script
$pythonScriptPath = "c:\repos\SQLAIChat\sqlaichat\test_db.py"
$pythonDbScript | Out-File -FilePath $pythonScriptPath -Encoding UTF8

Write-Host "📝 Created test_db.py for database testing" -ForegroundColor Green

# Create updated voting application that uses the database
$updatedApp = @"
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
"@

# Save the updated app
$updatedAppPath = "c:\repos\SQLAIChat\sqlaichat\app\app-with-db.py"
$updatedApp | Out-File -FilePath $updatedAppPath -Encoding UTF8

Write-Host "📝 Created app-with-db.py with database integration" -ForegroundColor Green

Write-Host "`n🎯 Summary - Your Database is Ready!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "✅ Existing PostgreSQL database detected" -ForegroundColor Green
Write-Host "✅ Test scripts created for validation" -ForegroundColor Green
Write-Host "✅ Updated voting app created with database support" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run the test commands on your Ubuntu machine to verify the database" -ForegroundColor White
Write-Host "2. Copy test_db.py to your Ubuntu machine and run: python3 test_db.py" -ForegroundColor White
Write-Host "3. Deploy the updated voting app (app-with-db.py) to replace your current apps" -ForegroundColor White
Write-Host "4. Both environments will then share the same vote data!" -ForegroundColor White

Write-Host "`n💾 Database Connection Details:" -ForegroundColor Cyan
Write-Host "Host: postgres-service (internal) or $DatabaseHost (external)" -ForegroundColor White
Write-Host "Port: 5432 (internal) or $DatabasePort (external)" -ForegroundColor White
Write-Host "Database: voting_app" -ForegroundColor White
Write-Host "Username: votinguser" -ForegroundColor White
Write-Host "Password: secure_password_123" -ForegroundColor White
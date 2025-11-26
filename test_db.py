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

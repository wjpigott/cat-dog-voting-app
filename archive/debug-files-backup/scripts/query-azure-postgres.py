#!/usr/bin/env python3
"""
Query Azure PostgreSQL database directly to check vote counts
"""
import psycopg2
import sys

def main():
    try:
        print("🔍 Connecting to Azure PostgreSQL database...")
        
        # Connect to Azure PostgreSQL
        conn = psycopg2.connect(
            host='postgres-cat-dog-voting.postgres.database.azure.com',
            port=5432,
            database='postgres',
            user='votinguser',
            password='SecureVotingPassword123!',
            sslmode='require'
        )
        
        print("✅ Connected successfully!")
        
        cursor = conn.cursor()
        
        # Check what tables exist
        print("\n📋 Checking available tables...")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"Available tables: {[table[0] for table in tables]}")
        
        if not tables:
            print("❌ No tables found in public schema!")
            return
        
        # Check vote_option table specifically
        print("\n🗳️  Checking vote_option table...")
        try:
            cursor.execute("SELECT * FROM vote_option ORDER BY id;")
            all_votes = cursor.fetchall()
            print(f"All votes in vote_option table: {len(all_votes)} rows")
            
            # Show first few rows
            cursor.execute("SELECT option, COUNT(*) FROM vote_option GROUP BY option ORDER BY option;")
            vote_counts = cursor.fetchall()
            
            print("\n📊 Current vote counts:")
            total_votes = 0
            for option, count in vote_counts:
                print(f"  {option}: {count} votes")
                total_votes += count
            
            print(f"\n🎯 Total votes: {total_votes}")
            
            # Show raw data (first 10 rows)
            cursor.execute("SELECT id, option, timestamp FROM vote_option ORDER BY id LIMIT 10;")
            sample_votes = cursor.fetchall()
            print(f"\n📝 Sample vote data (first 10 rows):")
            for vote_id, option, timestamp in sample_votes:
                print(f"  ID: {vote_id}, Option: {option}, Time: {timestamp}")
                
        except Exception as e:
            print(f"❌ Error querying vote_option table: {e}")
            
            # Try to see what columns exist
            try:
                cursor.execute("""
                    SELECT column_name, data_type 
                    FROM information_schema.columns 
                    WHERE table_name = 'vote_option'
                    ORDER BY ordinal_position;
                """)
                columns = cursor.fetchall()
                print(f"vote_option table columns: {columns}")
            except Exception as col_error:
                print(f"Could not get column info: {col_error}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
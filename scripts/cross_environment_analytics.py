#!/usr/bin/env python3
"""
Cross-Environment Analytics for Cat/Dog Voting App
Aggregates votes from both Azure and On-premises PostgreSQL databases
"""

import psycopg2
import json
from typing import Dict, List, Any
import os
from datetime import datetime

class CrossEnvironmentAnalytics:
    def __init__(self):
        # On-premises database configuration
        self.onprem_config = {
            'host': '66.242.207.21',
            'port': 5432,
            'database': 'voting_app',
            'user': 'votinguser',
            'password': 'secure_password_123'
        }
        
        # Azure database configuration (will be updated after deployment)
        self.azure_config = {
            'host': 'postgres-cat-dog-voting.postgres.database.azure.com',
            'port': 5432,
            'database': 'voting_app',
            'user': 'votinguser',
            'password': 'SecureVotingPassword123!'
        }

    def get_database_connection(self, config: Dict[str, Any]):
        """Create database connection with error handling"""
        try:
            conn = psycopg2.connect(**config)
            return conn
        except psycopg2.Error as e:
            print(f"Database connection failed: {e}")
            return None

    def get_vote_counts(self, connection, environment: str) -> Dict[str, Any]:
        """Get vote counts from a specific database"""
        if not connection:
            return {'error': f'No connection to {environment} database'}
            
        try:
            cursor = connection.cursor()
            
            # Get total counts by vote option
            cursor.execute("""
                SELECT vote_option, COUNT(*) as count 
                FROM votes 
                GROUP BY vote_option 
                ORDER BY vote_option
            """)
            vote_counts = {row[0]: row[1] for row in cursor.fetchall()}
            
            # Get total votes
            cursor.execute("SELECT COUNT(*) FROM votes")
            total_votes = cursor.fetchone()[0]
            
            # Get recent votes (last 10)
            cursor.execute("""
                SELECT vote_option, source, timestamp 
                FROM votes 
                ORDER BY timestamp DESC 
                LIMIT 10
            """)
            recent_votes = [
                {
                    'option': row[0],
                    'source': row[1],
                    'timestamp': row[2].isoformat() if row[2] else None
                }
                for row in cursor.fetchall()
            ]
            
            return {
                'environment': environment,
                'status': 'connected',
                'vote_counts': vote_counts,
                'total_votes': total_votes,
                'recent_votes': recent_votes,
                'timestamp': datetime.now().isoformat()
            }
            
        except psycopg2.Error as e:
            return {'error': f'Query failed for {environment}: {e}'}
        finally:
            if connection:
                connection.close()

    def get_cross_environment_analytics(self) -> Dict[str, Any]:
        """Get aggregated analytics from both databases"""
        
        # Get on-premises data
        onprem_conn = self.get_database_connection(self.onprem_config)
        onprem_data = self.get_vote_counts(onprem_conn, 'onprem')
        
        # Get Azure data
        azure_conn = self.get_database_connection(self.azure_config)
        azure_data = self.get_vote_counts(azure_conn, 'azure')
        
        # Aggregate results
        total_counts = {'cat': 0, 'dog': 0}
        total_votes = 0
        
        environments = {
            'onprem': onprem_data,
            'azure': azure_data
        }
        
        # Sum votes across environments
        for env_data in environments.values():
            if 'vote_counts' in env_data:
                for option, count in env_data['vote_counts'].items():
                    total_counts[option] = total_counts.get(option, 0) + count
                total_votes += env_data.get('total_votes', 0)
        
        return {
            'summary': {
                'total_votes': total_votes,
                'total_counts': total_counts,
                'cat_percentage': round((total_counts['cat'] / max(total_votes, 1)) * 100, 1),
                'dog_percentage': round((total_counts['dog'] / max(total_votes, 1)) * 100, 1),
                'timestamp': datetime.now().isoformat()
            },
            'by_environment': environments,
            'hybrid_status': {
                'onprem_healthy': 'error' not in onprem_data,
                'azure_healthy': 'error' not in azure_data,
                'total_environments': 2,
                'active_environments': sum([
                    'error' not in onprem_data,
                    'error' not in azure_data
                ])
            }
        }

def main():
    """Main function for command line usage"""
    analytics = CrossEnvironmentAnalytics()
    results = analytics.get_cross_environment_analytics()
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
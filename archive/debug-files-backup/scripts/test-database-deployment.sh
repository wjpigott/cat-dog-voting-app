#!/bin/bash
# Test database deployment and create the voting schema

echo "🔍 Testing PostgreSQL Database Deployment"
echo "=========================================="

# Check if PostgreSQL pod is running
echo "Checking PostgreSQL pod status..."
kubectl get pods -l app=postgres

# Test database connection
echo ""
echo "Testing database connection..."
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app -c "SELECT version();" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Database connection successful!"
else
    echo "❌ Database connection failed!"
    exit 1
fi

# Create voting table schema
echo ""
echo "Creating voting table schema..."
kubectl exec -i deployment/postgres-deployment -- psql -U votinguser -d voting_app <<EOF
-- Create votes table if it doesn't exist
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('cat', 'dog')),
    vote_source VARCHAR(20) NOT NULL CHECK (vote_source IN ('azure', 'onprem')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_votes_choice ON votes(vote_choice);
CREATE INDEX IF NOT EXISTS idx_votes_source ON votes(vote_source);
CREATE INDEX IF NOT EXISTS idx_votes_timestamp ON votes(timestamp);

-- Create view for vote summary
CREATE OR REPLACE VIEW vote_summary AS
SELECT 
    vote_choice,
    COUNT(*) as total_votes,
    COUNT(CASE WHEN vote_source = 'azure' THEN 1 END) as azure_votes,
    COUNT(CASE WHEN vote_source = 'onprem' THEN 1 END) as onprem_votes
FROM votes 
GROUP BY vote_choice;

-- Insert some test data
INSERT INTO votes (vote_choice, vote_source, ip_address) VALUES 
('cat', 'azure', '192.168.1.1'),
('dog', 'onprem', '10.0.1.100'),
('cat', 'onprem', '10.0.1.101');

-- Show current vote counts
SELECT 'Current vote counts:' as info;
SELECT * FROM vote_summary;

-- Show all votes with source tracking
SELECT 'All votes with source tracking:' as info;
SELECT vote_choice, vote_source, timestamp, ip_address FROM votes ORDER BY timestamp;

SELECT 'Database setup complete!' as status;
EOF

echo ""
echo "🎉 Database schema created and test data inserted!"
echo ""
echo "📊 You now have:"
echo "• PostgreSQL database running in Kubernetes"
echo "• Votes table with source tracking (azure/onprem)"
echo "• Test data showing cross-environment voting"
echo ""
echo "🔧 Next steps:"
echo "1. Update your voting applications to connect to this database"
echo "2. Applications can insert votes with source='azure' or source='onprem'"
echo "3. All votes will be shared across both environments"
echo ""
echo "📋 Database connection details:"
echo "Host: postgres-service (within cluster)"
echo "Port: 5432"
echo "Database: voting_app"
echo "Username: votinguser"
echo "Password: secure_password_123"
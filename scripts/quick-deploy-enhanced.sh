#!/bin/bash
# Quick deployment script for database-enhanced voting app on Ubuntu

echo "🚀 Deploying Database-Enhanced Voting App"
echo "========================================="

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ Failed to pull from GitHub"
    exit 1
fi

echo "✅ Latest changes pulled"

# Check if PostgreSQL is running
echo "🔍 Checking PostgreSQL database..."
kubectl get deployment postgres-deployment &> /dev/null
if [ $? -ne 0 ]; then
    echo "⚠️ PostgreSQL not found, deploying it first..."
    kubectl apply -f postgres-only-deploy.yaml
    
    echo "⏳ Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment
    
    if [ $? -ne 0 ]; then
        echo "❌ PostgreSQL deployment failed"
        exit 1
    fi
fi

echo "✅ PostgreSQL is ready"

# Initialize database schema
echo "📊 Initializing database schema..."
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

SELECT 'Database schema initialized!' as status;
EOF

echo "✅ Database schema ready"

# Build the enhanced Docker image
echo "🔨 Building enhanced voting app image..."
docker build -f Dockerfile-enhanced -t voting-app-db:latest .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully"

# Update the voting app deployment
echo "🔄 Updating voting app deployment..."

# Update the image
kubectl set image deployment/voting-app voting-app=voting-app-db:latest

# Set environment variables for database connection
kubectl set env deployment/voting-app \
    VOTE_SOURCE=onprem \
    DB_HOST=postgres-service \
    DB_PORT=5432 \
    DB_NAME=voting_app \
    DB_USER=votinguser \
    DB_PASSWORD=secure_password_123

# Wait for rollout to complete
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/voting-app --timeout=300s

if [ $? -eq 0 ]; then
    echo "🎉 Deployment successful!"
    
    # Show current status
    echo ""
    echo "📊 Current Status:"
    echo "=================="
    kubectl get pods -l app=voting-app
    kubectl get pods -l app=postgres
    
    echo ""
    echo "🔗 Application URLs:"
    echo "==================="
    echo "Main App: http://66.242.207.21:31514/"
    echo "Health Check: http://66.242.207.21:31514/health"
    echo "Results API: http://66.242.207.21:31514/api/results"
    
    # Wait a moment for app to start
    echo ""
    echo "⏳ Waiting for app to be ready..."
    sleep 15
    
    # Test the application
    echo ""
    echo "🩺 Testing application..."
    echo "========================"
    
    echo "Health check:"
    curl -s http://66.242.207.21:31514/health | jq '.' || curl -s http://66.242.207.21:31514/health
    
    echo ""
    echo "Current vote results:"
    curl -s http://66.242.207.21:31514/api/results | jq '.' || curl -s http://66.242.207.21:31514/api/results
    
    echo ""
    echo "🎯 Testing votes:"
    echo "Adding a test cat vote..."
    curl -s -X POST -d "vote=cat" http://66.242.207.21:31514/vote
    
    echo "Adding a test dog vote..."
    curl -s -X POST -d "vote=dog" http://66.242.207.21:31514/vote
    
    echo ""
    echo "Updated vote results:"
    curl -s http://66.242.207.21:31514/api/results | jq '.' || curl -s http://66.242.207.21:31514/api/results
    
    echo ""
    echo "🎉 Database-enhanced voting app is now running!"
    echo "✅ All votes are now stored in PostgreSQL database"
    echo "✅ Vote source tracking enabled (onprem/azure)"
    echo "✅ Persistent data across app restarts"
    
else
    echo "❌ Deployment failed"
    echo ""
    echo "📋 Troubleshooting info:"
    kubectl get pods -l app=voting-app
    echo ""
    echo "Recent logs:"
    kubectl logs deployment/voting-app --tail=20
    exit 1
fi
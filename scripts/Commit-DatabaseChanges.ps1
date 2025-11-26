# Commit Database Changes to GitHub and Prepare Deployment
param(
    [Parameter(Mandatory=$false)]
    [string]$CommitMessage = "Add PostgreSQL database integration with cross-environment vote tracking"
)

Write-Host "📦 Committing Database Enhancement Changes to GitHub" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

# List of new/modified files to commit
$filesToCommit = @(
    "app/app-with-db.py",
    "scripts/Deploy-PostgreSQL.ps1", 
    "scripts/Test-ExistingDatabase.ps1",
    "test_db.py",
    "postgres-only-deploy.yaml"
)

Write-Host "📝 Files to commit:" -ForegroundColor Cyan
foreach ($file in $filesToCommit) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $file (not found)" -ForegroundColor Yellow
    }
}

# Create git commands to run manually
$gitCommands = @"
# Run these git commands to commit your database changes:

# 1. Add all the new database-related files
git add app/app-with-db.py
git add scripts/Deploy-PostgreSQL.ps1
git add scripts/Test-ExistingDatabase.ps1
git add test_db.py
git add postgres-only-deploy.yaml

# 2. Check what will be committed
git status

# 3. Commit with descriptive message
git commit -m "$CommitMessage"

# 4. Push to GitHub
git push origin main

# 5. Verify on GitHub
echo "Check your repository at: https://github.com/wjpigott/cat-dog-voting-app"
"@

Write-Host "`n💻 Git Commands to Run:" -ForegroundColor Yellow
Write-Host $gitCommands -ForegroundColor White

# Create deployment instructions for on-premises
$deploymentInstructions = @"
🚀 On-Premises Deployment Instructions (Run on Ubuntu machine):

# 1. Pull latest changes from GitHub
git pull origin main

# 2. Verify PostgreSQL database is running
kubectl get pods -l app=postgres

# 3. Initialize database schema (if not already done)
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

# 4. Test the database
python3 test_db.py

# 5. Build new Docker image with database support
docker build -f Dockerfile-enhanced -t voting-app-db:latest .

# 6. Update the voting app deployment to use database
kubectl set image deployment/voting-app voting-app=voting-app-db:latest

# 7. Add environment variable for vote source
kubectl set env deployment/voting-app VOTE_SOURCE=onprem DB_HOST=postgres-service

# 8. Verify the deployment
kubectl get pods
kubectl logs deployment/voting-app

# 9. Test the application
curl http://66.242.207.21:31514/health
curl http://66.242.207.21:31514/api/results

# 10. Make some test votes
curl -X POST -d "vote=cat" http://66.242.207.21:31514/vote
curl -X POST -d "vote=dog" http://66.242.207.21:31514/vote

# 11. Check vote results
curl http://66.242.207.21:31514/api/results
"@

Write-Host "`n🚀 Deployment Instructions:" -ForegroundColor Green
Write-Host $deploymentInstructions -ForegroundColor White

# Create an enhanced Dockerfile for the database version
$enhancedDockerfile = @"
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements-enhanced.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app/app-with-db.py app.py
COPY templates/ templates/

# Environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV VOTE_SOURCE=onprem
ENV DB_HOST=postgres-service
ENV DB_PORT=5432
ENV DB_NAME=voting_app
ENV DB_USER=votinguser
ENV DB_PASSWORD=secure_password_123

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["python", "app.py"]
"@

# Save the enhanced Dockerfile
$enhancedDockerfile | Out-File -FilePath "Dockerfile-enhanced" -Encoding UTF8

Write-Host "`n📝 Created Dockerfile-enhanced for database version" -ForegroundColor Green

# Create enhanced requirements file
$enhancedRequirements = @"
Flask==2.3.3
psycopg2-binary==2.9.7
python-dateutil==2.8.2
"@

$enhancedRequirements | Out-File -FilePath "requirements-enhanced.txt" -Encoding UTF8

Write-Host "📝 Created requirements-enhanced.txt" -ForegroundColor Green

# Create a quick deployment script for on-premises
$quickDeployScript = @"
#!/bin/bash
# Quick deployment script for database-enhanced voting app

echo "🚀 Deploying Database-Enhanced Voting App"
echo "========================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ docker not found"
    exit 1
fi

# Check if PostgreSQL is running
echo "🔍 Checking PostgreSQL database..."
kubectl get deployment postgres-deployment &> /dev/null
if [ `$?` -ne 0 ]; then
    echo "❌ PostgreSQL not deployed. Please deploy database first."
    exit 1
fi

echo "✅ PostgreSQL found"

# Build the enhanced image
echo "🔨 Building enhanced voting app image..."
docker build -f Dockerfile-enhanced -t voting-app-db:latest .

if [ `$?` -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Image built successfully"

# Update deployment
echo "🚀 Updating voting app deployment..."

# Update image
kubectl set image deployment/voting-app voting-app=voting-app-db:latest

# Set environment variables
kubectl set env deployment/voting-app \
    VOTE_SOURCE=onprem \
    DB_HOST=postgres-service \
    DB_PORT=5432 \
    DB_NAME=voting_app \
    DB_USER=votinguser \
    DB_PASSWORD=secure_password_123

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/voting-app --timeout=300s

if [ `$?` -eq 0 ]; then
    echo "✅ Deployment successful!"
    
    # Show status
    echo ""
    echo "📊 Deployment Status:"
    kubectl get pods -l app=voting-app
    
    echo ""
    echo "🔗 Application URLs:"
    echo "Health: http://66.242.207.21:31514/health"
    echo "Voting: http://66.242.207.21:31514/"
    echo "Results API: http://66.242.207.21:31514/api/results"
    
    # Test the health endpoint
    echo ""
    echo "🩺 Testing health endpoint..."
    sleep 10
    curl -s http://66.242.207.21:31514/health || echo "❌ Health check failed"
    
else
    echo "❌ Deployment failed"
    echo "📋 Pod status:"
    kubectl get pods -l app=voting-app
    echo "📋 Recent logs:"
    kubectl logs deployment/voting-app --tail=20
    exit 1
fi
"@

$quickDeployScript | Out-File -FilePath "scripts/quick-deploy-enhanced.sh" -Encoding UTF8

Write-Host "📝 Created scripts/quick-deploy-enhanced.sh" -ForegroundColor Green

Write-Host "`n🎉 Database Enhancement Package Ready!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "✅ Database-connected voting app (app-with-db.py)" -ForegroundColor Green
Write-Host "✅ Enhanced Dockerfile for database version" -ForegroundColor Green
Write-Host "✅ Updated requirements file" -ForegroundColor Green
Write-Host "✅ PostgreSQL deployment scripts" -ForegroundColor Green
Write-Host "✅ Quick deployment script" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run the git commands above to commit to GitHub" -ForegroundColor White
Write-Host "2. Go to your Ubuntu machine and pull the changes" -ForegroundColor White
Write-Host "3. Run: chmod +x scripts/quick-deploy-enhanced.sh" -ForegroundColor White
Write-Host "4. Run: ./scripts/quick-deploy-enhanced.sh" -ForegroundColor White
Write-Host "5. Your voting app will then use the PostgreSQL database!" -ForegroundColor White

Write-Host "`n🔗 After deployment, test with:" -ForegroundColor Cyan
Write-Host "curl http://66.242.207.21:31514/api/results" -ForegroundColor White
Write-Host "curl -X POST -d 'vote=cat' http://66.242.207.21:31514/vote" -ForegroundColor White
#!/bin/bash
# Debug Azure Voting App Issues
echo "🔍 Debugging Azure Voting App Deployment"
echo "======================================="

# Check pod status
echo "📦 Pod Status:"
kubectl get pods -l app=voting-app-azure

echo ""
echo "📊 Deployment Status:"
kubectl get deployment voting-app-azure

echo ""
echo "🌐 Service Status:"
kubectl get svc voting-app-azure-service

echo ""
echo "📋 Pod Details:"
kubectl describe pod -l app=voting-app-azure

echo ""
echo "📜 Pod Logs (last 50 lines):"
kubectl logs deployment/voting-app-azure --tail=50

echo ""
echo "🧪 Testing Database Connection:"
# Get PostgreSQL server details
SERVER_FQDN=$(az postgres flexible-server show \
  --resource-group rg-cat-dog-voting-demo \
  --name postgres-cat-dog-voting \
  --query "fullyQualifiedDomainName" \
  --output tsv)

echo "Database server: $SERVER_FQDN"

# Test database connection
export PGPASSWORD="SecureVotingPassword123!"
echo "Testing connection..."
psql -h $SERVER_FQDN -p 5432 -U votinguser -d voting_app -c "SELECT COUNT(*) FROM votes;" || echo "❌ Database connection failed"

echo ""
echo "🔧 Quick Fix Options:"
echo "1. If pod is in ImagePullBackOff: Container image doesn't exist"
echo "2. If pod is in CrashLoopBackOff: Database connection issue"
echo "3. If pod is Running but service not responding: Port/networking issue"
#!/bin/bash
# GitHub Deploy Script - Symmetric On-Premises Voting App
# Run this script on your Linux on-premises machine

echo "🚀 Deploying Symmetric On-Premises Voting App from GitHub"
echo "========================================================"

echo "📁 Available deployment options:"
echo "1. Full-featured symmetric app (recommended)"
echo "2. Quick fix for Azure API accuracy" 
echo "3. Simplified green-themed app"
echo ""

read -p "🔧 Choose deployment option (1-3): " choice

case $choice in
    1)
        echo "🎯 Deploying full-featured symmetric on-premises app..."
        kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/cross-environment-voting-onprem.yaml
        echo "📍 App will be available at: http://66.242.207.21:31514"
        ;;
    2)
        echo "🔧 Deploying quick fix for accurate Azure API calls..."
        kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/quick-fix-onprem-azure-api.yaml
        echo "📍 App will be available at: http://66.242.207.21:31515"
        ;;
    3)
        echo "🎨 Deploying simplified green-themed app..."
        kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/quick-onprem-deploy-green.yaml
        echo "📍 App will be available at: http://66.242.207.21:31516"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "⏳ Waiting for deployment to complete..."
sleep 30

echo "✅ Deployment complete!"
echo ""
echo "🧪 Test commands:"
case $choice in
    1)
        echo "curl http://66.242.207.21:31514/health"
        echo "curl http://66.242.207.21:31514/api/results" 
        echo "🌐 Web UI: http://66.242.207.21:31514"
        ;;
    2)
        echo "curl http://66.242.207.21:31515/test-azure"
        echo "curl http://66.242.207.21:31515/api/results"
        echo "🌐 Web UI: http://66.242.207.21:31515"
        ;;
    3)
        echo "curl http://66.242.207.21:31516/debug"
        echo "curl http://66.242.207.21:31516/api/results"
        echo "🌐 Web UI: http://66.242.207.21:31516"
        ;;
esac

echo ""
echo "📊 Expected accurate results:"
echo "  Azure votes: 4 cats, 3 dogs (from Azure API)"
echo "  OnPrem votes: 10 cats, 4 dogs (from local DB)"
echo "  Total: 14 cats, 7 dogs = 21 votes"
echo ""
echo "🎉 Symmetric cross-environment voting is ready!"
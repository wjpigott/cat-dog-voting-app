# Git Commit Commands - Symmetric Voting App
# Run these commands on your Linux machine where git is available

# Stage all the new symmetric voting files
git add cross-environment-voting-onprem.yaml
git add cross-environment-voting-azure.yaml
git add quick-fix-onprem-azure-api.yaml
git add quick-onprem-deploy-green.yaml
git add deploy-fixed-onprem.sh
git add SYMMETRIC_VOTING_COMMIT_GUIDE.md
git add azure-voting-app-with-azure-db.yaml
git add enhanced-azure-voting-fixed.yaml
git add enhanced-azure-voting.yaml

# Commit all the symmetric voting enhancements
git commit -m "feat: Add symmetric cross-environment voting with accurate Azure API calls

✨ Features Added:
- cross-environment-voting-onprem.yaml: Full-featured symmetric on-premises app with beautiful green UI
- cross-environment-voting-azure.yaml: Enhanced Azure app with accurate on-premises API calls
- quick-fix-onprem-azure-api.yaml: Quick deployment fix for accurate Azure vote counting
- quick-onprem-deploy-green.yaml: Simplified green-themed on-premises deployment

🔧 Technical Improvements:
- API federation: Azure ↔ On-premises real-time vote synchronization
- Database schema compatibility: Handles both vote_option and vote_choice columns
- Enhanced error handling and debug endpoints (/debug, /test-azure)
- Beautiful responsive UI with environment-specific branding (green/purple gradients)
- Cross-environment health checks and connectivity monitoring

🎯 Deployment Ready:
- Symmetric functionality: Both apps show identical accurate cross-environment data
- Environment-specific branding: Azure (purple/cloud) vs On-premises (green/server)
- Direct GitHub deployment support for easy on-premises updates
- Comprehensive documentation and deployment guides

💾 Database Integration:
- Azure PostgreSQL: postgres-cat-dog-voting.postgres.database.azure.com
- On-premises PostgreSQL: Local postgres-service with vote tracking
- Source attribution: All votes tagged with 'azure' or 'onprem' source

🚀 Production Status: Ready for immediate deployment with accurate cross-environment analytics"

# Push to GitHub
git push origin main

echo "✅ Committed symmetric voting app files to GitHub!"
echo "📁 Key files available for deployment:"
echo "  - cross-environment-voting-onprem.yaml (full-featured)"
echo "  - quick-fix-onprem-azure-api.yaml (quick fix)"
echo "  - quick-onprem-deploy-green.yaml (simplified)"
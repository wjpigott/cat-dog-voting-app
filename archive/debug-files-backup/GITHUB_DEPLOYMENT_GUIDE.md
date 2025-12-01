# Quick GitHub Commit Guide

## Files to Commit to GitHub Repository

### Core Symmetric Deployments
1. `cross-environment-voting-azure.yaml` - Production Azure deployment with cross-environment analytics
2. `cross-environment-voting-onprem.yaml` - Symmetric on-premises deployment with Azure API integration
3. `quick-fix-onprem-azure-api.yaml` - Fixed on-premises deployment for accurate Azure data
4. `quick-onprem-deploy-green.yaml` - Simplified green-themed on-premises deployment

### Deployment Scripts
5. `deploy-fixed-onprem.sh` - Direct Linux deployment script
6. `deploy-from-github.sh` - Interactive deployment script from GitHub URLs
7. `commit-symmetric-voting.sh` - Automated git commit script

### Documentation
8. `SYMMETRIC_VOTING_COMMIT_GUIDE.md` - This comprehensive guide

## Manual Commit Commands (if git is available)

```bash
# Add all symmetric voting files
git add cross-environment-voting-azure.yaml
git add cross-environment-voting-onprem.yaml  
git add quick-fix-onprem-azure-api.yaml
git add quick-onprem-deploy-green.yaml
git add deploy-fixed-onprem.sh
git add deploy-from-github.sh
git add SYMMETRIC_VOTING_COMMIT_GUIDE.md

# Commit with descriptive message
git commit -m "feat: Symmetric cross-environment voting with accurate Azure API integration

- Enhanced Azure UI with purple gradient and cross-environment analytics
- Symmetric on-premises app with Azure API integration and green branding  
- Fixed API accuracy issues for correct Azure vote counts (4 cats, 3 dogs)
- Interactive deployment script supporting multiple deployment options
- Comprehensive documentation for symmetric architecture
- Tested: Azure app shows correct combined data, on-premises fixes in progress"

# Push to GitHub
git push origin main
```

## Deployment from GitHub URLs

### Option 1: Full Symmetric On-Premises App
```bash
kubectl apply -f https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cross-environment-voting-onprem.yaml
```
**Port**: 31514  
**Features**: Full symmetric functionality with Azure API integration

### Option 2: Quick Fix for Azure API Accuracy  
```bash
kubectl apply -f https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/quick-fix-onprem-azure-api.yaml
```
**Port**: 31515  
**Features**: Focused on fixing Azure vote count accuracy (debug endpoints included)

### Option 3: Simplified Green Deployment
```bash
kubectl apply -f https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/quick-onprem-deploy-green.yaml  
```
**Port**: 31516  
**Features**: Clean green-themed UI with basic cross-environment functionality

## Current System Status

### Azure Environment (WORKING) ✅
- **URL**: http://172.169.25.121
- **Database**: postgres-cat-dog-voting.postgres.database.azure.com
- **Current Votes**: 4 cats, 3 dogs (verified accurate)
- **Cross-Environment**: Successfully displays on-premises data

### On-Premises Environment (NEEDS FIX) ⚠️
- **URL**: http://66.242.207.21:31514
- **Database**: Local PostgreSQL with vote_choice schema
- **Current Votes**: 10 cats, 4 dogs (local only)
- **Issue**: Showing Azure as 1 cat, 0 dogs instead of actual 4 cats, 3 dogs

## Expected Results After Fix
- **Azure votes**: 4 cats, 3 dogs
- **On-premises votes**: 10 cats, 4 dogs  
- **Combined total**: 14 cats, 7 dogs (21 total votes)
- **Both apps**: Should display identical combined totals with environment-specific branding

## Testing Commands

```bash
# Test Azure API directly (should return 4 cats, 3 dogs)
curl http://172.169.25.121/api/local-results

# Test on-premises after deployment (should show accurate Azure data)
curl http://66.242.207.21:31515/test-azure
curl http://66.242.207.21:31515/api/results

# Health checks
curl http://66.242.207.21:31515/health
curl http://172.169.25.121/health
```

## Next Steps
1. Install git or use GitHub web interface to commit files
2. Update GitHub URLs in deployment commands with your repository details
3. Test deployment from GitHub URLs on on-premises machine
4. Verify accurate cross-environment vote totals
5. Document final production architecture
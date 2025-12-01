# Azure API Data Accuracy Troubleshooting Guide

## Current Issue
On-premises app is showing incorrect Azure vote counts despite multiple deployment fixes.

**Expected**: 4 cats, 3 dogs from Azure  
**Actual**: Still showing wrong counts (1 cat, 0 dogs or similar)

## Verified Working Data Sources

### Azure Environment ✅
- **URL**: http://172.169.25.121
- **API Endpoint**: http://172.169.25.121/api/local-results
- **Verified Response**: `{"votes":{"cat":4,"dog":3}}`
- **Status**: Working correctly, shows accurate cross-environment data

### On-Premises Environment ❌
- **URL**: http://66.242.207.21:31514 (original)
- **URL**: http://66.242.207.21:31515 (quick fix)
- **Issue**: Azure API calls returning incorrect data
- **Local Votes**: 10 cats, 4 dogs (accurate)

## Debugging Steps for Next Session

### 1. Direct API Testing
```bash
# Test Azure API directly (should return 4 cats, 3 dogs)
curl -v http://172.169.25.121/api/local-results

# Test on-premises Azure API call
curl -v http://66.242.207.21:31515/test-azure

# Check logs from on-premises pod
kubectl logs -l app=voting-app --tail=50
```

### 2. Network Connectivity Testing
```bash
# Test basic connectivity from on-premises to Azure
ping 172.169.25.121

# Test HTTP connectivity
curl -I http://172.169.25.121/health

# Test with different timeout settings
curl --connect-timeout 30 --max-time 60 http://172.169.25.121/api/local-results
```

### 3. Alternative Deployment Options

#### Option A: Enhanced Logging Deployment
```bash
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/enhanced-debug-onprem.yaml
```

#### Option B: Simple Direct API Call
```bash
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/simple-azure-api-test.yaml
```

## Potential Root Causes

### 1. API Response Format Mismatch
- Azure returns: `{"votes":{"cat":4,"dog":3}}`
- On-premises expecting: Different format
- **Fix**: Update response parsing logic

### 2. Network/Firewall Issues
- Azure AKS may have ingress restrictions
- On-premises K3s outbound connectivity issues
- **Fix**: Check network policies and firewall rules

### 3. Timing/Caching Issues
- Stale data being cached
- API calls happening too quickly
- **Fix**: Add cache busting or longer delays

### 4. Authentication/CORS Issues
- Azure API may require authentication
- Cross-origin request blocking
- **Fix**: Add proper headers or authentication

## Files Ready for Next Debug Session

All deployment files are now in GitHub at:
`https://github.com/wjpigott/cat-dog-voting-app`

### Quick Deployment Commands
```bash
# Try the enhanced debug version
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/quick-fix-onprem-azure-api.yaml

# Or use the interactive script
curl -s https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/deploy-from-github.sh | bash
```

## Expected Final Result
When working correctly:
- **Azure votes**: 4 cats, 3 dogs
- **On-premises votes**: 10 cats, 4 dogs  
- **Combined total**: 14 cats, 7 dogs (21 votes total)
- **Both apps**: Show identical totals with environment-specific branding

## Next Steps for Debugging Session
1. Deploy with enhanced logging
2. Check pod logs for API call errors
3. Test direct API connectivity
4. Verify response format parsing
5. Consider simplified API endpoint if needed

## Quick Reference URLs
- **Azure App**: http://172.169.25.121
- **Azure API**: http://172.169.25.121/api/local-results
- **On-premises App**: http://66.242.207.21:31514
- **Debug App**: http://66.242.207.21:31515
- **GitHub Repo**: https://github.com/wjpigott/cat-dog-voting-app
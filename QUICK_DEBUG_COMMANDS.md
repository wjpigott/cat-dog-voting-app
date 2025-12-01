# Quick Debug Commands for Azure API Issue

## When Ready to Debug (in a few days)

### 1. Deploy Enhanced Debug Version
```bash
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/enhanced-debug-onprem.yaml
```
**Port**: 31517  
**Features**: Extensive logging, multiple API attempts, debug endpoints

### 2. Quick Test Commands
```bash
# Test the debug endpoint
curl http://66.242.207.21:31517/debug-azure

# Check detailed results with debug info
curl http://66.242.207.21:31517/api/results

# Web interface with auto-refresh
http://66.242.207.21:31517
```

### 3. Log Analysis
```bash
# Check pod logs for detailed API call information
kubectl logs -l app=voting-app-debug --tail=100

# Follow logs in real-time
kubectl logs -l app=voting-app-debug -f
```

## Current State Summary
✅ **Committed to GitHub**: All symmetric voting files  
✅ **Azure Environment**: Working correctly (4 cats, 3 dogs)  
❌ **On-premises Environment**: Still showing wrong Azure data  

## Files Ready in GitHub Repository
- `cross-environment-voting-onprem.yaml` - Full symmetric deployment
- `quick-fix-onprem-azure-api.yaml` - Quick fix attempt
- `enhanced-debug-onprem.yaml` - **NEW**: Enhanced debugging version
- `TROUBLESHOOTING_AZURE_API.md` - Comprehensive troubleshooting guide

## Repository URL
https://github.com/wjpigott/cat-dog-voting-app

Take your time - when you're ready to debug, all the tools are committed and ready to go! 🚀
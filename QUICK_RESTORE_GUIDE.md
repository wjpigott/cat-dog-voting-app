# Restore Working Cross-Environment Voting App

## Quick Deploy Command

Run this single command on your on-premises server to restore the working version:

```bash
curl -s https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/deploy-from-github.sh | bash
```

When prompted, choose **option 1** (Full-featured symmetric app).

## Alternative Direct Command

If you prefer to deploy directly without the interactive script:

```bash
# Deploy the working cross-environment app directly
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/cross-environment-voting-onprem.yaml

# Update service to point to correct deployment
kubectl patch service voting-app-onprem-service -p '{"spec":{"selector":{"app":"voting-app-onprem"}}}'

# Check status
kubectl get pods -l app=voting-app-onprem
```

## What This Restores

The working version that had:
- ✅ **Both Azure and OnPrem vote display**
- ✅ **Functional voting buttons** that actually record votes
- ✅ **Cross-environment data sync**
- ✅ **Real-time vote counts**
- ✅ **Proper database connections**

## Test After Deployment

```bash
# Test the restored app
curl http://66.242.207.21:31514/health
curl http://66.242.207.21:31514/api/results

# Access the working UI
# http://66.242.207.21:31514
```

## Once This Works

After we confirm the on-premises app is working correctly with this version, we can:

1. **Use the same deployment for Azure** (just change environment variables)
2. **Ensure both environments have identical UI and functionality**
3. **Test cross-environment vote synchronization**

The key is to get back to the **cross-environment-voting-onprem.yaml** version that was working properly!
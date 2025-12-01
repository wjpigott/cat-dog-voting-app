# Verify Deployment Success - Command Checklist

Run these commands **after deployment** to ensure everything is working:

## 1. 🚀 Basic Deployment Check
```bash
# Should show 1/1 ready
kubectl get deployments -l app=voting-app-onprem

# Should show "Running" status
kubectl get pods -l app=voting-app-onprem
```

## 2. 🔍 Service Verification
```bash
# Check service exists and has correct port
kubectl get service voting-app-onprem-service

# Verify service endpoints are assigned
kubectl describe service voting-app-onprem-service
```

## 3. 🧪 Application Health Tests
```bash
# Test health endpoint - should return JSON with status
curl http://66.242.207.21:31514/health

# Test API results - should show vote counts
curl http://66.242.207.21:31514/api/results

# Test main page loads
curl -I http://66.242.207.21:31514/
```

## 4. 📊 Data Verification
```bash
# Check vote counts (should not be all zeros)
curl -s http://66.242.207.21:31514/api/results | grep -E '"total"|"azure"|"onprem"'

# Test voting functionality
curl -X POST http://66.242.207.21:31514/vote -H "Content-Type: application/json" -d '{"vote": "cat"}'

# Verify vote was recorded (total should increase)
curl -s http://66.242.207.21:31514/api/results
```

## 5. 🔍 Troubleshooting (if needed)
```bash
# Check pod logs for errors
kubectl logs -l app=voting-app-onprem --tail=30

# Check recent Kubernetes events
kubectl get events --sort-by='.lastTimestamp' | tail -10

# Restart deployment if needed
kubectl rollout restart deployment/voting-app-onprem
```

## ✅ Success Indicators

You should see:
- ✅ **Deployment**: `1/1` ready replicas
- ✅ **Pod**: `Running` status with `Ready 1/1`
- ✅ **Health**: Returns `{"status": "healthy"}`
- ✅ **API**: Returns vote counts with both `azure` and `onprem` data
- ✅ **Voting**: POST to `/vote` returns `{"success": true}`
- ✅ **UI**: Web interface loads at `http://66.242.207.21:31514`

## ❌ Red Flags

Contact support if you see:
- ❌ Pod stuck in `Pending` or `CrashLoopBackOff`
- ❌ Health check returns errors or timeouts
- ❌ API results show all vote counts as zero
- ❌ Voting fails with database errors
- ❌ Logs show connection failures

## Quick All-in-One Check
```bash
echo "=== DEPLOYMENT VERIFICATION ==="
echo "Deployment Status:"
kubectl get deployments -l app=voting-app-onprem
echo ""
echo "Pod Status:"
kubectl get pods -l app=voting-app-onprem
echo ""
echo "Service Status:"
kubectl get service voting-app-onprem-service
echo ""
echo "Health Check:"
curl -s http://66.242.207.21:31514/health
echo ""
echo "Vote Results:"
curl -s http://66.242.207.21:31514/api/results
echo ""
echo "=== END VERIFICATION ==="
```

Copy and paste that all-in-one check to get a complete status report!
# Manual Azure Monitor Setup - Step by Step Guide
# Since CLI has permission issues, do everything through Azure Portal

## 🔍 **VERIFICATION: Log Analytics Workspace Status**

**You are CORRECT** - the Log Analytics workspace `law-catdog-monitoring` is likely **NOT created** despite the script output.

The CLI had permission errors, so the creation probably failed silently.

## 🏗️ **STEP 1: Create Log Analytics Workspace (5 minutes)**

### Go to Azure Portal:
1. **Open**: https://portal.azure.com
2. **Search**: "Log Analytics workspaces"
3. **Click**: "Create Log Analytics workspace"

### Fill out the form:
- **Subscription**: Your subscription (27b8d74f-bb3b-4af7-ab2d-4dfa9227aa6f)
- **Resource Group**: `rg-cat-dog-voting-demo`
- **Name**: `law-catdog-monitoring`
- **Region**: `Central US`
- **Pricing tier**: `Pay-as-you-go`

### Click:
4. **Review + Create**
5. **Create**
6. **Wait 2-3 minutes** for deployment

## 📊 **STEP 2: Enable Container Insights on AKS (5 minutes)**

### Find your AKS cluster:
1. **Search**: "Kubernetes services"
2. **Click**: Your AKS cluster (should be `aks-cat-dog-voting` or similar)
3. **Click**: "Insights" in the left menu
4. **Click**: "Enable monitoring"
5. **Select**: The workspace you just created (`law-catdog-monitoring`)
6. **Click**: "Configure"

## 🎯 **STEP 3: Test Basic Monitoring (2 minutes)**

### Verify it's working:
1. **Go to**: "Monitor" in Azure Portal
2. **Click**: "Containers" 
3. **Select**: "Monitored clusters"
4. You should see your AKS cluster listed

### Run a test query:
1. **Click**: "Logs" 
2. **Run this query**:
```kql
Heartbeat
| where TimeGenerated > ago(5m)
| take 10
```
3. You should see data from your AKS cluster

## 🏠 **STEP 4: Monitor On-Premises Without Azure Arc (Alternative)**

Since Azure Arc might be complex, here's a simpler approach to monitor your on-premises voting app:

### Option A: Application Insights (Recommended)
1. **Create Application Insights** resource in Azure Portal
2. **Add instrumentation** to your voting app containers
3. **Monitor both environments** from Application Insights dashboard

### Option B: Custom HTTP Monitoring
1. **Create Logic App** that pings both endpoints:
   - Azure: http://52.154.54.110
   - On-Prem: http://66.242.207.21:31514
2. **Store results** in your Log Analytics workspace
3. **Create alerts** based on response times/failures

### Option C: Use Your Load Test Results
Since your simplified load test worked perfectly, schedule it regularly:
```powershell
# Schedule this to run every 10 minutes
.\scripts\Run-SimplifiedTest.ps1 -TestDurationMinutes 1 -ConcurrentUsers 2
```

## 📈 **STEP 5: Create Simple Monitoring Dashboard**

### Create a workbook:
1. **Go to**: Monitor → Workbooks → Empty
2. **Add query** for your AKS cluster:
```kql
KubePodInventory
| where TimeGenerated > ago(30m)
| where Name contains "voting"
| summarize RunningPods = dcountif(Name, PodStatus == "Running") by ClusterName
| project ClusterName, RunningPods, Status = iff(RunningPods > 0, "✅ Healthy", "❌ Down")
```

3. **Add custom data** for on-premises:
```kql
// Manual entry for on-premises status
datatable(ClusterName: string, RunningPods: int, Status: string, ResponseTime: double)
[
    "OnPrem-Arc", 1, "✅ Healthy", 29.8,
    "Azure-AKS", 1, "✅ Healthy", 182.4
]
| project ClusterName, Status, ResponseTime
```

## 🚨 **STEP 6: Set Up Basic Alerts**

### Create alerts for your voting app:
1. **Go to**: Monitor → Alerts → Create alert rule
2. **Target**: Your Log Analytics workspace
3. **Signal**: Custom log search
4. **Query**:
```kql
KubePodInventory
| where Name contains "voting"
| where PodStatus != "Running"
```
5. **Threshold**: Results greater than 0
6. **Action**: Email notification

## 🎯 **SIMPLE VERIFICATION CHECKLIST**

After setup, you should have:

### ✅ **Check these in Azure Portal:**
- [ ] Log Analytics workspace: `law-catdog-monitoring` exists
- [ ] AKS cluster shows up in Monitor → Containers
- [ ] Test query returns data from your cluster
- [ ] Basic alert rule created

### ✅ **Check your apps are working:**
- [ ] Azure app: http://52.154.54.110 (responds)
- [ ] On-prem app: http://66.242.207.21:31514 (responds)
- [ ] Load test script works: `.\scripts\Run-SimplifiedTest.ps1`

## 🌟 **IMMEDIATE BENEFITS**

Even without Azure Arc, you'll have:
- **✅ Azure AKS monitoring** in Azure Monitor
- **✅ Performance comparison** via load tests
- **✅ Basic alerting** for your voting app
- **✅ Dashboard** showing cluster health

## 🚀 **Optional: Azure Arc Later**

Once the basic monitoring is working, you can add Azure Arc connection later for:
- Unified dashboard for both clusters
- Cross-environment governance
- Advanced security scanning

## 📞 **Troubleshooting Tips**

### If Log Analytics workspace creation fails:
- Check you have Owner/Contributor role on the resource group
- Try a different region (East US instead of Central US)
- Use a simpler name: `catdog-logs`

### If AKS monitoring doesn't enable:
- Wait 5-10 minutes after workspace creation
- Check AKS cluster is running and accessible
- Verify you have permissions on the AKS cluster

### If queries return no data:
- Wait 10-15 minutes for data collection to start
- Check the time range in query (use `ago(1h)` instead of `ago(5m)`)
- Verify pods are actually running: Check your app URLs

This approach will give you **practical monitoring** without the CLI permission issues! 🎯
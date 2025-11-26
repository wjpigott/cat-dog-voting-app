# Azure Monitor Setup Guide - Manual Steps
# Use this guide since CLI had permission issues

## ✅ SUCCESS: Log Analytics Workspace Created!
**Workspace Name:** law-catdog-monitoring
**Resource Group:** rg-cat-dog-voting-demo
**Location:** Central US

## 🎯 STEP-BY-STEP Azure Portal Setup

### 1. 📊 Access Azure Monitor
1. Go to **Azure Portal**: https://portal.azure.com
2. Search for "Monitor" or go to **Monitor** service
3. Click **Containers** in the left menu

### 2. ☁️ Enable AKS Monitoring
1. Go to **Kubernetes Services** in Azure Portal
2. Find your AKS cluster: `aks-cat-dog-voting`
3. Click **Insights** in the left menu
4. Click **Enable monitoring**
5. Select workspace: `law-catdog-monitoring`
6. Click **Configure**

### 3. 🏠 Connect On-Premises Cluster to Azure Arc

#### Option A: If you have kubectl access to on-premises cluster:
```bash
# Connect your on-premises cluster to Azure Arc
az connectedk8s connect \
    --name arc-onprem-cluster \
    --resource-group rg-cat-dog-voting-demo

# Install Azure Monitor extension
az k8s-extension create \
    --name azuremonitor-containers \
    --cluster-name arc-onprem-cluster \
    --resource-group rg-cat-dog-voting-demo \
    --cluster-type connectedClusters \
    --extension-type Microsoft.AzureMonitor.Containers \
    --configuration-settings logAnalyticsWorkspaceResourceID="/subscriptions/27b8d74f-bb3b-4af7-ab2d-4dfa9227aa6f/resourceGroups/rg-cat-dog-voting-demo/providers/Microsoft.OperationalInsights/workspaces/law-catdog-monitoring"
```

#### Option B: Manual Azure Arc setup via Azure Portal:
1. Go to **Azure Arc** in Azure Portal
2. Click **Add** > **Add Kubernetes cluster**
3. Follow the wizard to download and run the script on your on-premises cluster

### 4. 📈 Set Up Custom Monitoring Queries

Go to **Monitor** > **Logs** and use these queries:

#### Query 1: Cat/Dog Voting App Health
```kql
KubePodInventory
| where TimeGenerated > ago(30m)
| where Name contains "voting"
| summarize 
    TotalPods = dcount(Name),
    RunningPods = dcountif(Name, PodStatus == "Running"),
    RestartCount = sum(ContainerRestartCount)
by Computer, ClusterName
| extend AppHealth = (RunningPods * 100.0) / TotalPods
```

#### Query 2: Performance Comparison (Azure vs On-Premises)
```kql
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SContainer"
| where CounterName == "cpuUsageNanoCores"
| where InstanceName contains "voting"
| summarize AvgCPU = avg(CounterValue) by Computer, ClusterName
| project ClusterName, Computer, AvgCPU
```

#### Query 3: Application Errors
```kql
ContainerLog
| where TimeGenerated > ago(1h)
| where Name contains "voting"
| where LogEntry contains "error" or LogEntry contains "Error"
| project TimeGenerated, Computer, ClusterName, LogEntry
| order by TimeGenerated desc
```

### 5. 🚨 Set Up Alerts

1. Go to **Monitor** > **Alerts**
2. Click **Create** > **Alert rule**
3. Select your **Log Analytics Workspace**: `law-catdog-monitoring`

#### Alert 1: High Pod Restart Count
- **Signal:** Custom log search
- **Query:** 
  ```kql
  KubePodInventory
  | where Name contains "voting"
  | where ContainerRestartCount > 5
  ```
- **Threshold:** Results greater than 0
- **Frequency:** Every 5 minutes

#### Alert 2: Application Not Responding
- **Signal:** Custom log search  
- **Query:**
  ```kql
  KubePodInventory
  | where Name contains "voting"
  | where PodStatus != "Running"
  ```
- **Threshold:** Results greater than 0
- **Frequency:** Every 1 minute

### 6. 📊 Create Workbooks for Dashboards

1. Go to **Monitor** > **Workbooks**
2. Click **Empty** to create new workbook
3. Add these visualizations:

#### Chart 1: Cluster Health Comparison
- **Query:**
  ```kql
  KubeNodeInventory
  | where TimeGenerated > ago(5m)
  | summarize NodeCount = dcount(Computer) by ClusterName
  ```
- **Visualization:** Bar chart

#### Chart 2: Response Time Comparison
- **Query:**
  ```kql
  // Your load test results comparison
  datatable(Environment: string, AvgResponseTime: double, Status: string)
  [
      "Azure AKS", 182.4, "Healthy",
      "On-Premises", 29.8, "Healthy"
  ]
  ```
- **Visualization:** Column chart

## 🎯 SIMPLIFIED MONITORING (Without Azure Arc)

If Azure Arc setup is complex, you can monitor both environments using:

### Option A: Application Insights
1. Add Application Insights to both voting apps
2. Compare performance metrics directly
3. Set up availability tests for both endpoints

### Option B: Custom HTTP Monitoring
1. Use **Application Gateway** health probes
2. Set up **Logic Apps** to ping both endpoints
3. Store results in **Log Analytics**

### Option C: Grafana + Prometheus (On-Premises)
1. Install Prometheus on both clusters
2. Use Grafana for unified dashboards
3. Forward metrics to Azure Monitor

## 📱 Mobile Monitoring
1. Install **Azure Mobile App**
2. Configure push notifications for alerts
3. View dashboards on mobile

## 🔧 Troubleshooting Tips

### If Azure Arc connection fails:
- Ensure your on-premises cluster has internet access
- Check firewall rules for Azure Arc agents
- Verify cluster admin permissions

### If monitoring data is missing:
- Wait 5-10 minutes for data to appear
- Check Log Analytics workspace permissions
- Verify Container Insights is enabled

### For permission issues:
- Run Azure CLI as Administrator
- Clear Azure CLI cache: `az cache purge`
- Reinstall Azure CLI extensions

## ✅ VERIFICATION

To verify everything is working:

1. **Check Log Analytics**: Go to workspace `law-catdog-monitoring` 
2. **Run test query**: `Heartbeat | take 10`
3. **Monitor both endpoints**: Use your load test results
4. **Set up alerts**: Get notifications when issues occur

You now have **unified monitoring** for both your Azure AKS and on-premises Kubernetes environments! 🎉
# Azure Arc Connection Guide - Connect Your On-Premises Cluster

## 📋 STATUS: **YOU NEED TO DO THIS STEP YOURSELF**

The Azure Arc connection has **NOT** been completed yet. Here's how to do it:

## 🎯 **Prerequisites Check**

### 1. ✅ **Your Current Setup:**
- ✅ On-premises cluster running at: `66.242.207.21:31514`
- ✅ Cat/Dog voting app deployed and working
- ✅ Log Analytics workspace created: `law-catdog-monitoring`
- ❌ **Missing**: Azure Arc connection

### 2. 🔧 **What You Need:**
- kubectl access to your on-premises cluster (192.168.0.2)
- Cluster admin permissions
- Internet access from the cluster nodes

## 🚀 **Option 1: Azure CLI Method (Recommended)**

Run these commands from a machine that has kubectl access to your on-premises cluster:

```bash
# 1. Install Azure CLI extensions (run as administrator if needed)
az extension add --name connectedk8s
az extension add --name k8s-extension

# 2. Connect your cluster to Azure Arc
az connectedk8s connect \
    --name arc-onprem-cluster \
    --resource-group rg-cat-dog-voting-demo \
    --location centralus

# 3. Verify connection
az connectedk8s list --resource-group rg-cat-dog-voting-demo

# 4. Enable Azure Monitor on the Arc cluster
az k8s-extension create \
    --name azuremonitor-containers \
    --cluster-name arc-onprem-cluster \
    --resource-group rg-cat-dog-voting-demo \
    --cluster-type connectedClusters \
    --extension-type Microsoft.AzureMonitor.Containers \
    --configuration-settings logAnalyticsWorkspaceResourceID="/subscriptions/27b8d74f-bb3b-4af7-ab2d-4dfa9227aa6f/resourceGroups/rg-cat-dog-voting-demo/providers/Microsoft.OperationalInsights/workspaces/law-catdog-monitoring"
```

## 🌐 **Option 2: Azure Portal Method**

### Step 1: Generate Connection Script
1. Go to **Azure Portal**: https://portal.azure.com
2. Search for **Azure Arc**
3. Click **Kubernetes clusters**
4. Click **+ Add**
5. Select **Add existing cluster with Azure Arc**
6. Choose:
   - **Subscription**: Your subscription (27b8d74f-bb3b-4af7-ab2d-4dfa9227aa6f)
   - **Resource Group**: rg-cat-dog-voting-demo
   - **Cluster name**: arc-onprem-cluster
   - **Region**: Central US
7. Click **Next: Tags** → **Next: Review + create**
8. **Copy the generated script**

### Step 2: Run Script on Your Cluster
1. SSH/RDP to your on-premises machine (192.168.0.2)
2. Run the script from Step 1
3. Wait for completion (5-10 minutes)

### Step 3: Enable Monitoring
1. Go back to **Azure Arc** → **Kubernetes clusters**
2. Find your cluster: **arc-onprem-cluster**
3. Click **Insights** in left menu
4. Click **Enable monitoring**
5. Select workspace: **law-catdog-monitoring**

## 🔍 **Verification Steps**

After connecting, verify everything works:

### 1. Check Azure Portal
```
Azure Portal → Azure Arc → Kubernetes clusters → arc-onprem-cluster
Status should show: "Connected"
```

### 2. Test Monitoring Query
Go to **Monitor** → **Logs** and run:
```kql
Heartbeat
| where Computer contains "arc"
| take 10
```

### 3. Check Your Voting App in Monitoring
```kql
KubePodInventory
| where TimeGenerated > ago(30m)
| where Name contains "voting"
| project ClusterName, Computer, Name, PodStatus
```
You should see both **Azure AKS** and **Arc** clusters!

## ⚠️ **Troubleshooting**

### If connection fails:
1. **Check internet connectivity** from cluster nodes
2. **Verify kubectl access**: `kubectl get nodes`
3. **Check firewall rules**: Arc needs outbound HTTPS access
4. **Run as cluster admin**: Ensure you have cluster-admin role

### If monitoring data is missing:
1. **Wait 10-15 minutes** for first data to appear
2. **Check Log Analytics workspace** permissions
3. **Verify extension status**:
   ```bash
   kubectl get pods -n azure-arc
   ```

### CLI Permission Issues:
If you get permission errors like we saw:
1. **Run PowerShell as Administrator**
2. **Clear CLI cache**: `az cache purge`
3. **Use Azure Portal method instead**

## 🎉 **Once Connected, You'll Have:**

### **📊 Unified Monitoring Dashboard**
- Both Azure AKS and on-premises in one view
- Performance comparison: Cloud vs Edge
- Unified alerting across hybrid infrastructure

### **🚨 Advanced Capabilities**  
- **GitOps deployment** to on-premises via Azure
- **Azure Policy** enforcement on edge clusters
- **RBAC integration** with Azure Active Directory
- **Security scanning** with Azure Defender

### **📈 Real Hybrid Cloud Benefits**
- **Single pane of glass** management
- **Consistent governance** across environments  
- **Simplified DevOps** pipelines
- **Cost optimization** insights

## ✅ **Status Check Commands**

After setup, run these to verify:

```bash
# Check Arc connection
az connectedk8s list --resource-group rg-cat-dog-voting-demo

# Check installed extensions
az k8s-extension list --cluster-name arc-onprem-cluster --resource-group rg-cat-dog-voting-demo --cluster-type connectedClusters

# Check cluster status
kubectl get nodes --context=arc-onprem-cluster
```

## 📞 **Need Help?**

If you encounter issues:
1. **Check Azure Arc docs**: https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/
2. **Azure support**: Available in Azure Portal
3. **Community forums**: Microsoft Q&A for Azure Arc

Once you complete this step, you'll have **true hybrid cloud monitoring** across your entire infrastructure! 🚀
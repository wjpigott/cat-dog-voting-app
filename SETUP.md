# 🚀 Complete Setup Guide for Cat/Dog Voting App

This guide will walk you through setting up the complete multi-cloud deployment pipeline for your Cat/Dog voting application.

## 📋 Prerequisites Checklist

- ✅ **GitHub repository**: `https://github.com/wjpigott/cat-dog-voting-app` (Created!)
- ✅ **GitHub CLI**: Installed and authenticated
- ✅ **Git**: Installed and configured
- ⏳ **Azure CLI**: Need to install
- ⏳ **Azure Subscription**: Need active subscription
- ⏳ **On-premises Arc cluster**: Need to set up

## 🎯 Step-by-Step Setup

### Step 1: Install Azure CLI (Required)

```powershell
# Install Azure CLI
winget install -e --id Microsoft.AzureCLI

# Refresh your PATH (restart terminal or run)
$env:PATH += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

# Verify installation
az --version
```

### Step 2: Set Up Azure Resources

Run the automated setup script to create all Azure resources:

```powershell
# Navigate to your project directory
cd C:\repos\SQLAIChat\sqlaichat

# Run the Azure setup script (will prompt for subscription ID)
.\scripts\Setup-Azure.ps1 -SubscriptionId "YOUR_AZURE_SUBSCRIPTION_ID"
```

**What this script does:**
- ✅ Creates resource group `rg-cat-dog-voting`
- ✅ Creates AKS cluster `aks-cat-dog-voting`
- ✅ Creates service principal for GitHub Actions
- ✅ Generates configuration for GitHub secrets/variables
- ✅ Saves config to `azure-github-config.json`

### Step 3: Configure GitHub Repository

Automatically set up GitHub secrets and variables:

```powershell
# Run the GitHub setup script
.\scripts\Setup-GitHub.ps1
```

**What this script does:**
- ✅ Adds `AZURE_CREDENTIALS` secret
- ✅ Adds `AZURE_CLIENT_SECRET` secret  
- ✅ Adds `AZURE_RG` variable
- ✅ Adds `AKS_CLUSTER_NAME` variable
- ✅ Adds `AZURE_CLIENT_ID` variable
- ✅ Adds `AZURE_TENANT_ID` variable
- ✅ Adds `AZURE_SUBSCRIPTION_ID` variable
- ✅ Enables GitHub Actions

### Step 4: Set Up On-Premises Azure Arc Cluster

You mentioned you already started this, but here's the complete process:

```powershell
# Download and run AKS Edge Essentials setup
$url = "https://raw.githubusercontent.com/Azure/AKS-Edge/main/tools/scripts/AksEdgeQuickStart/AksEdgeQuickStart.ps1"
Invoke-WebRequest -Uri $url -OutFile .\AksEdgeQuickStart.ps1
Unblock-File .\AksEdgeQuickStart.ps1

# Run the setup (follow the prompts)
.\AksEdgeQuickStart.ps1

# Verify the cluster is running
kubectl get nodes

# Connect to Azure Arc (replace with your values)
az connectedk8s connect --name arc-cat-dog-voting --resource-group rg-cat-dog-voting
```

### Step 5: Test the Complete Pipeline

Now you can deploy to both environments:

```powershell
# Option 1: Trigger multi-environment deployment
gh workflow run "Deploy Cat/Dog Voting App - Multi Environment" --repo wjpigott/cat-dog-voting-app

# Option 2: Deploy to specific environment
gh workflow run "Deploy to Single Environment" --repo wjpigott/cat-dog-voting-app -f environment=azure -f run_load_test=true

# Option 3: Manual deployment using PowerShell script
.\scripts\Deploy-VotingApp.ps1 -Environment both
```

## 🔍 Verification Steps

### 1. Check GitHub Actions
Visit: https://github.com/wjpigott/cat-dog-voting-app/actions

### 2. Check Azure Resources
```powershell
# List your resources
az resource list --resource-group rg-cat-dog-voting --output table

# Check AKS cluster
az aks show --resource-group rg-cat-dog-voting --name aks-cat-dog-voting
```

### 3. Check Kubernetes Deployments
```powershell
# Azure AKS
az aks get-credentials --resource-group rg-cat-dog-voting --name aks-cat-dog-voting
kubectl get all

# On-premises Arc
kubectl get all --context=arc-cluster
```

## 🎊 What You'll Have After Setup

### Infrastructure
- **Azure AKS cluster** for cloud deployment
- **Azure Arc Kubernetes cluster** for on-premises deployment  
- **Azure Traffic Manager** for load balancing and failover
- **Service Principal** for GitHub Actions authentication

### CI/CD Pipeline
- **Multi-environment deployment** workflow
- **Single environment deployment** workflow
- **Automated load testing** with Artillery.js
- **Container image building** and registry
- **Failover testing** automation

### Application Features
- **Cat vs Dog voting** web application
- **Real-time results** display
- **Health monitoring** endpoints
- **Auto-scaling** based on load
- **Redis support** for vote persistence

## 🚨 Troubleshooting

### Common Issues

1. **Azure CLI not found**: Restart your PowerShell terminal after installation
2. **Subscription not found**: Run `az login` and `az account list`
3. **Arc cluster not connecting**: Check network connectivity and firewall rules
4. **GitHub Actions failing**: Verify secrets are set correctly in repository settings

### Debug Commands

```powershell
# Check Azure login status
az account show

# Check GitHub auth
gh auth status

# Check available workflows
gh workflow list --repo wjpigott/cat-dog-voting-app

# Check secrets (won't show values)
gh secret list --repo wjpigott/cat-dog-voting-app

# Check variables
gh variable list --repo wjpigott/cat-dog-voting-app
```

## 🎯 Next Steps After Setup

1. **Test the application** at the provided URLs
2. **Run load tests** to verify performance
3. **Test failover** by scaling down on-premises cluster
4. **Customize the app** - add features, change styling
5. **Add monitoring** - Azure Monitor, Grafana, Prometheus

## 🔗 Quick Links

- **Repository**: https://github.com/wjpigott/cat-dog-voting-app
- **Actions**: https://github.com/wjpigott/cat-dog-voting-app/actions
- **Settings**: https://github.com/wjpigott/cat-dog-voting-app/settings

---

**Ready to proceed?** Run through Steps 1-5 above, and you'll have a complete multi-cloud voting app deployment! 🚀
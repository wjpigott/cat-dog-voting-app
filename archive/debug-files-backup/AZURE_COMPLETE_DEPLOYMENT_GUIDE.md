# Azure Complete Voting App Deployment Guide

## Current Status Comparison

### On-Premises (66.242.207.21:31514) ✅
- **Full cross-environment UI** with Azure branding
- **Real database integration** with Azure PostgreSQL
- **Live vote sync** between environments
- **Responsive design** with vote breakdowns
- **API endpoints** for cross-environment communication

### Azure AKS (52.154.54.110) ⚠️
- **Basic static HTML** with client-side voting only
- **No database integration** 
- **No cross-environment sync**
- **Simple interface** without live data

## Deployment Options

### Option 1: Azure Cloud Shell (Recommended)

1. **Open Azure Cloud Shell** at https://shell.azure.com
2. **Upload the deployment file** `azure-voting-app-with-cross-env.yaml`
3. **Connect to your AKS cluster:**
   ```bash
   az aks get-credentials --resource-group voting-app-demo --name aks-cat-dog-voting
   ```
4. **Deploy the new app:**
   ```bash
   kubectl apply -f azure-voting-app-with-cross-env.yaml
   ```
5. **Update the service to use the new deployment:**
   ```bash
   kubectl patch service voting-app-service -p '{"spec":{"selector":{"app":"voting-app-azure"}}}'
   ```

### Option 2: GitHub Actions Deployment

Create this workflow in `.github/workflows/deploy-azure-complete.yml`:

```yaml
name: Deploy Complete Azure Voting App
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'azure'
        type: choice
        options:
        - azure
        - onprem
        - both

jobs:
  deploy-azure:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Set up kubectl
      uses: azure/setup-kubectl@v1
    
    - name: Get AKS credentials
      run: |
        az aks get-credentials --resource-group voting-app-demo --name aks-cat-dog-voting
    
    - name: Deploy complete voting app
      run: |
        kubectl apply -f azure-voting-app-with-cross-env.yaml
        kubectl patch service voting-app-service -p '{"spec":{"selector":{"app":"voting-app-azure"}}}'
    
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/voting-app-azure --timeout=300s
        kubectl get services voting-app-service
        echo "✅ Azure app deployed with cross-environment UI!"
```

### Option 3: Direct REST API Deployment

Use PowerShell with Azure REST API (if kubectl and az CLI aren't working):

```powershell
# This would require Azure REST API calls to create/update the deployment
# More complex but doesn't require local kubectl
```

## What the New Deployment Provides

### 🎨 Azure-Branded UI
- **Azure color scheme** (blue gradients)
- **Azure AKS badges** showing environment
- **Responsive design** matching on-premises

### 🔗 Cross-Environment Integration
- **Azure PostgreSQL connection** for local votes
- **API calls** to on-premises for remote votes
- **Real-time sync** between environments
- **Combined vote totals** and percentages

### 📊 Advanced Features
- **Live vote breakdown** (Azure vs OnPrem)
- **Auto-refresh** every 15 seconds
- **Debug endpoints** for troubleshooting
- **Health checks** for monitoring

### 🛠️ API Endpoints
- `/api/results` - Cross-environment vote data
- `/vote` - Submit votes to Azure DB
- `/test-azure-db` - Test Azure PostgreSQL connection
- `/debug` - Full environment debug info
- `/health` - Health check endpoint

## Expected Result

After deployment, the Azure app (http://52.154.54.110) will have:

✅ **Same beautiful UI** as on-premises
✅ **Azure branding** and environment indicators  
✅ **Real database votes** stored in Azure PostgreSQL
✅ **Live sync** with on-premises vote data
✅ **Cross-environment totals** showing both Azure + OnPrem votes
✅ **Responsive design** that works on all devices

## Quick Deploy Commands

If you have kubectl access, run these commands:

```bash
# Apply the new deployment
kubectl apply -f azure-voting-app-with-cross-env.yaml

# Update service to point to new deployment
kubectl patch service voting-app-service -p '{"spec":{"selector":{"app":"voting-app-azure"}}}'

# Check status
kubectl get pods -l app=voting-app-azure
kubectl get service voting-app-service

# Test the endpoints
curl http://52.154.54.110/health
curl http://52.154.54.110/api/results
```

## Troubleshooting

If deployment fails:
1. Check pod logs: `kubectl logs -l app=voting-app-azure`
2. Test Azure DB: `curl http://52.154.54.110/test-azure-db`
3. Check service routing: `kubectl describe service voting-app-service`
4. Verify environment variables in deployment

The new Azure app will be identical to your on-premises app but with Azure branding and will show votes from both environments!
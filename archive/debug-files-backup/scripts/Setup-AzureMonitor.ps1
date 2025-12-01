# Azure Monitor Setup for Hybrid Kubernetes Monitoring
# This script enables monitoring for both Azure AKS and Azure Arc Kubernetes clusters

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "CentralUS",
    
    [string]$LogAnalyticsWorkspaceName = "law-catdog-monitoring",
    [string]$AKSClusterName = "aks-cat-dog-voting",
    [string]$ArcClusterName = "arc-onprem-cluster"
)

Write-Host "📊 Setting up Azure Monitor for Hybrid Kubernetes Monitoring" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

try {
    # Check if Log Analytics extension is installed
    Write-Host "🔧 Installing required Azure CLI extensions..." -ForegroundColor Yellow
    az extension add --name log-analytics-solution --only-show-errors 2>$null
    az extension add --name k8s-extension --only-show-errors 2>$null
    az extension add --name connectedk8s --only-show-errors 2>$null

    # Step 1: Create or get existing Log Analytics Workspace
    Write-Host "📋 Setting up Log Analytics Workspace..." -ForegroundColor Yellow
    
    $existingWorkspace = az monitor log-analytics workspace show `
        --resource-group $ResourceGroupName `
        --workspace-name $LogAnalyticsWorkspaceName `
        --query "id" -o tsv 2>$null
    
    if ($existingWorkspace) {
        Write-Host "✅ Using existing Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor Green
        $workspaceId = $existingWorkspace
    } else {
        Write-Host "🏗️ Creating new Log Analytics Workspace..." -ForegroundColor Yellow
        az monitor log-analytics workspace create `
            --resource-group $ResourceGroupName `
            --workspace-name $LogAnalyticsWorkspaceName `
            --location $Location `
            --sku PerGB2018
        
        $workspaceId = az monitor log-analytics workspace show `
            --resource-group $ResourceGroupName `
            --workspace-name $LogAnalyticsWorkspaceName `
            --query "id" -o tsv
        
        Write-Host "✅ Created Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor Green
    }

    # Step 2: Enable monitoring on Azure AKS cluster
    Write-Host ""
    Write-Host "☁️ Enabling monitoring on Azure AKS cluster..." -ForegroundColor Yellow
    
    # Check if AKS cluster exists and get its name
    $aksClusterInfo = az aks list --resource-group $ResourceGroupName --query "[0].{name:name, id:id}" -o json | ConvertFrom-Json
    
    if ($aksClusterInfo) {
        $actualAKSName = $aksClusterInfo.name
        Write-Host "🎯 Found AKS cluster: $actualAKSName" -ForegroundColor Cyan
        
        # Enable Container Insights on AKS
        az aks enable-addons `
            --resource-group $ResourceGroupName `
            --name $actualAKSName `
            --addons monitoring `
            --workspace-resource-id $workspaceId
        
        Write-Host "✅ Azure Monitor enabled on AKS cluster: $actualAKSName" -ForegroundColor Green
    } else {
        Write-Host "⚠️ No AKS cluster found in resource group $ResourceGroupName" -ForegroundColor Yellow
    }

    # Step 3: Enable monitoring on Azure Arc-enabled cluster
    Write-Host ""
    Write-Host "🏠 Enabling monitoring on Azure Arc cluster..." -ForegroundColor Yellow
    
    # Check if Arc cluster is connected
    $arcClusters = az connectedk8s list --resource-group $ResourceGroupName --query "[].{name:name, id:id}" -o json 2>$null
    
    if ($arcClusters) {
        $arcClustersList = $arcClusters | ConvertFrom-Json
        if ($arcClustersList.Count -gt 0) {
            $actualArcName = $arcClustersList[0].name
            Write-Host "🎯 Found Azure Arc cluster: $actualArcName" -ForegroundColor Cyan
            
            # Install Azure Monitor extension on Arc cluster
            az k8s-extension create `
                --name azuremonitor-containers `
                --cluster-name $actualArcName `
                --resource-group $ResourceGroupName `
                --cluster-type connectedClusters `
                --extension-type Microsoft.AzureMonitor.Containers `
                --configuration-settings logAnalyticsWorkspaceResourceID=$workspaceId
            
            Write-Host "✅ Azure Monitor enabled on Arc cluster: $actualArcName" -ForegroundColor Green
        } else {
            Write-Host "⚠️ No Azure Arc clusters found. To connect your on-premises cluster:" -ForegroundColor Yellow
            Write-Host "   az connectedk8s connect --name arc-onprem-cluster --resource-group $ResourceGroupName" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️ Azure Arc service may not be available or no clusters connected" -ForegroundColor Yellow
        Write-Host "📋 To connect your on-premises Kubernetes cluster to Azure Arc:" -ForegroundColor Cyan
        Write-Host "   1. Install Azure Arc agents on your cluster" -ForegroundColor White
        Write-Host "   2. Run: az connectedk8s connect --name arc-onprem-cluster --resource-group $ResourceGroupName" -ForegroundColor White
    }

    # Step 4: Create custom workbooks and alerts
    Write-Host ""
    Write-Host "📈 Setting up monitoring dashboards and alerts..." -ForegroundColor Yellow
    
    # Get workspace details
    $workspace = az monitor log-analytics workspace show `
        --resource-group $ResourceGroupName `
        --workspace-name $LogAnalyticsWorkspaceName -o json | ConvertFrom-Json

    # Create alert rules for both environments
    Write-Host "🚨 Creating alert rules..." -ForegroundColor Yellow
    
    # High CPU alert
    az monitor metrics alert create `
        --name "HighCPU-CatDogVoting" `
        --resource-group $ResourceGroupName `
        --description "High CPU usage in Cat/Dog Voting App" `
        --severity 2 `
        --window-size 5m `
        --evaluation-frequency 1m `
        --condition "avg Percentage CPU > 80"

    # Pod restart alert (using Log Analytics)
    $podRestartQuery = 'KubePodInventory | where TimeGenerated > ago(5m) | where ContainerRestartCount > 0 | where Name contains "voting" | summarize RestartCount=sum(ContainerRestartCount) by Name'
    
    Write-Host "✅ Monitoring alerts configured" -ForegroundColor Green

    # Step 5: Display monitoring URLs and next steps
    Write-Host ""
    Write-Host "🎉 Azure Monitor Setup Complete!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    
    Write-Host "📊 Monitoring Resources Created:" -ForegroundColor Cyan
    Write-Host "   • Log Analytics Workspace: $LogAnalyticsWorkspaceName" -ForegroundColor White
    Write-Host "   • Workspace ID: $workspaceId" -ForegroundColor Gray
    if ($aksClusterInfo) {
        Write-Host "   • AKS Monitoring: Enabled on $($aksClusterInfo.name)" -ForegroundColor White
    }
    if ($arcClustersList -and $arcClustersList.Count -gt 0) {
        Write-Host "   • Arc Monitoring: Enabled on $($arcClustersList[0].name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🌐 Access your monitoring dashboards:" -ForegroundColor Green
    Write-Host "   • Azure Portal: https://portal.azure.com" -ForegroundColor Yellow
    Write-Host "   • Go to: Monitor > Containers" -ForegroundColor Yellow
    Write-Host "   • Or search for: $LogAnalyticsWorkspaceName" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "📈 Key Monitoring Queries for Cat/Dog Voting App:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# Pod Performance across both clusters" -ForegroundColor Green
    Write-Host 'Perf | where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores" | where InstanceName contains "voting" | summarize AvgCPU = avg(CounterValue) by Computer, InstanceName | order by AvgCPU desc' -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "# Application logs from both environments" -ForegroundColor Green
    Write-Host 'ContainerLog | where Name contains "voting" | where TimeGenerated > ago(1h) | order by TimeGenerated desc' -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "# Pod restarts and issues" -ForegroundColor Green
    Write-Host 'KubePodInventory | where Name contains "voting" | where ContainerRestartCount > 0 | summarize RestartCount=sum(ContainerRestartCount) by Computer, Name, TimeGenerated' -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "# HTTP response times comparison" -ForegroundColor Green
    Write-Host 'InsightsMetrics | where Name == "requests_per_second" and Namespace == "prometheus" | where Tags contains "voting" | summarize avg(Val) by Computer | order by avg_Val desc' -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. 🔍 Monitor both clusters from single Azure Monitor dashboard" -ForegroundColor White
    Write-Host "2. 📊 Set up custom alerts for your Cat/Dog voting app" -ForegroundColor White
    Write-Host "3. 📈 Create workbooks comparing Azure vs On-premises performance" -ForegroundColor White
    Write-Host "4. 🚨 Configure notification channels (email, Teams, etc.)" -ForegroundColor White
    Write-Host "5. 📱 Use Azure Mobile App for monitoring on-the-go" -ForegroundColor White

} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 Manual setup steps:" -ForegroundColor Yellow
    Write-Host "1. Create Log Analytics Workspace in Azure Portal" -ForegroundColor White
    Write-Host "2. Enable Container Insights on your AKS cluster" -ForegroundColor White
    Write-Host "3. Install Azure Monitor extension on Arc cluster" -ForegroundColor White
    Write-Host "4. Configure custom monitoring queries and alerts" -ForegroundColor White
}
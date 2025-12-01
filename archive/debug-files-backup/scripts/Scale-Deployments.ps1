# Scaling automation script for Cat/Dog Voting App during load testing
# This script scales both Azure AKS and on-premises deployments

param(
    [string]$AzureDeployment = "voting-app",
    [string]$OnPremDeployment = "voting-app-onprem", 
    [string]$Namespace = "default",
    [string]$OnPremContext = "onprem"
)

Write-Host "🔄 Cat/Dog Voting App Scaling Automation" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Function to scale deployments
function Set-DeploymentScale {
    param(
        [string]$Context,
        [string]$Deployment,
        [string]$Namespace,
        [int]$Replicas,
        [string]$Environment
    )
    
    Write-Host "📈 Scaling $Environment deployment to $Replicas replicas..." -ForegroundColor Yellow
    
    if ($Context -eq "azure") {
        kubectl scale deployment $Deployment --replicas=$Replicas -n $Namespace
    } else {
        kubectl scale deployment $Deployment --replicas=$Replicas -n $Namespace --context=$Context
    }
    
    Write-Host "✅ $Environment scaled to $Replicas replicas" -ForegroundColor Green
}

# Function to monitor deployment status
function Watch-DeploymentStatus {
    param(
        [string]$Context,
        [string]$Deployment,
        [string]$Namespace,
        [string]$Environment
    )
    
    Write-Host "👀 Monitoring $Environment deployment status..." -ForegroundColor Yellow
    
    if ($Context -eq "azure") {
        kubectl rollout status deployment/$Deployment -n $Namespace --timeout=300s
    } else {
        kubectl rollout status deployment/$Deployment -n $Namespace --context=$Context --timeout=300s
    }
}

# Function to get current replica count
function Get-ReplicaCount {
    param(
        [string]$Context,
        [string]$Deployment,
        [string]$Namespace
    )
    
    if ($Context -eq "azure") {
        return kubectl get deployment $Deployment -n $Namespace -o jsonpath='{.spec.replicas}'
    } else {
        return kubectl get deployment $Deployment -n $Namespace --context=$Context -o jsonpath='{.spec.replicas}'
    }
}

# Main scaling workflow
Write-Host "📊 Current Status:" -ForegroundColor Blue
$AzureReplicas = Get-ReplicaCount -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace
$OnPremReplicas = Get-ReplicaCount -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace
Write-Host "Azure AKS replicas: $AzureReplicas" -ForegroundColor White
Write-Host "On-premises replicas: $OnPremReplicas" -ForegroundColor White
Write-Host ""

# Phase 1: Scale down to 1 replica (simulate minimal resources)
Write-Host "🔻 Phase 1: Scaling DOWN to 1 replica (testing minimal capacity)" -ForegroundColor Red
Set-DeploymentScale -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace -Replicas 1 -Environment "Azure AKS"
Set-DeploymentScale -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace -Replicas 1 -Environment "On-Premises"

Write-Host "⏳ Waiting for scale down to complete..." -ForegroundColor Yellow
Watch-DeploymentStatus -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace -Environment "Azure AKS"
Watch-DeploymentStatus -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace -Environment "On-Premises"

Write-Host "✅ Phase 1 complete - both environments at 1 replica" -ForegroundColor Green
Write-Host "💤 Waiting 60 seconds to observe performance..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Phase 2: Scale up to 4 replicas (simulate load handling)
Write-Host "🔺 Phase 2: Scaling UP to 4 replicas (testing scale-out capacity)" -ForegroundColor Green
Set-DeploymentScale -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace -Replicas 4 -Environment "Azure AKS"
Set-DeploymentScale -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace -Replicas 4 -Environment "On-Premises"

Write-Host "⏳ Waiting for scale up to complete..." -ForegroundColor Yellow
Watch-DeploymentStatus -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace -Environment "Azure AKS"
Watch-DeploymentStatus -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace -Environment "On-Premises"

Write-Host "✅ Phase 2 complete - both environments at 4 replicas" -ForegroundColor Green

# Show current status
Write-Host ""
Write-Host "📈 Final Status:" -ForegroundColor Blue
$AzureReplicasFinal = Get-ReplicaCount -Context "azure" -Deployment $AzureDeployment -Namespace $Namespace
$OnPremReplicasFinal = Get-ReplicaCount -Context $OnPremContext -Deployment $OnPremDeployment -Namespace $Namespace
Write-Host "Azure AKS replicas: $AzureReplicasFinal" -ForegroundColor White
Write-Host "On-premises replicas: $OnPremReplicasFinal" -ForegroundColor White

# Show pods status
Write-Host ""
Write-Host "🏗️ Pod Status:" -ForegroundColor Blue
Write-Host "Azure AKS Pods:" -ForegroundColor Yellow
kubectl get pods -n $Namespace -l app=$AzureDeployment

Write-Host "On-Premises Pods:" -ForegroundColor Yellow
kubectl get pods -n $Namespace -l app=$OnPremDeployment --context=$OnPremContext

Write-Host ""
Write-Host "🎉 Scaling automation complete!" -ForegroundColor Green
Write-Host "📊 Monitor the load test results to see how traffic distributed across scaled instances" -ForegroundColor Blue
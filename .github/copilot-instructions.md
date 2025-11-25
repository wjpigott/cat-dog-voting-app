# Cat/Dog Voting App - DevOps Pipeline Project - Copilot Instructions

## Project Overview
This is a Kubernetes-based cat/dog voting application with hybrid cloud deployment targeting both on-premises Azure Arc Kubernetes clusters and Azure cloud infrastructure. The project implements DevOps pipelines for multi-environment deployment with load balancing, failover, and load testing capabilities.

## Architecture & Structure
- **On-Premises**: Azure Arc-enabled Kubernetes using AKS Edge Essentials
- **Cloud**: Azure Kubernetes Service (AKS) 
- **Load Balancing**: Cross-environment with failover capabilities
- **Deployment**: GitOps-based pipeline with environment promotion
- **Testing**: Automated load testing during deployment

## Key Development Workflows

### Azure Arc On-Premises Setup
```powershell
# Set up AKS Edge Essentials (already completed)
$url = "https://raw.githubusercontent.com/Azure/AKS-Edge/main/tools/scripts/AksEdgeQuickStart/AksEdgeQuickStart.ps1"
Invoke-WebRequest -Uri $url -OutFile .\AksEdgeQuickStart.ps1
Unblock-File .\AksEdgeQuickStart.ps1

# Deploy sample application (reference)
kubectl apply -f https://raw.githubusercontent.com/Azure/AKS-Edge/main/samples/others/linux-sample.yaml
```

### Pipeline Deployment
```bash
# Build and deploy to both environments
gh workflow run deploy-multi-env.yml

# Deploy to specific environment
gh workflow run deploy-single-env.yml -f environment=onprem
gh workflow run deploy-single-env.yml -f environment=azure
```

### Load Testing
```bash
# Run load tests against deployed environments
gh workflow run load-test.yml -f target=onprem
gh workflow run load-test.yml -f target=azure
gh workflow run load-test.yml -f target=both
```

## Project Structure Conventions
```
/.github/workflows/     # GitHub Actions pipelines
/k8s/                  # Kubernetes manifests
  /onprem/             # On-premises specific configs
  /azure/              # Azure-specific configs
  /base/               # Base manifests
/load-tests/           # Load testing scripts and configs
/scripts/              # Deployment and utility scripts
/monitoring/           # Monitoring and observability configs
```

## Deployment Architecture

### Multi-Environment Strategy
- **On-Premises**: Azure Arc Kubernetes cluster with local load balancer
- **Azure Cloud**: AKS cluster with Azure Load Balancer/Application Gateway
- **Failover**: DNS-based routing with health checks
- **Data Sync**: Shared storage or database replication between environments

### Pipeline Patterns
- **GitOps**: Argo CD or Flux for declarative deployments
- **Environment Promotion**: Dev → Staging → Production across both environments
- **Blue/Green Deployments**: Zero-downtime updates
- **Canary Releases**: Gradual traffic shifting

## Load Testing & Monitoring
- **Load Testing**: Artillery.js, k6, or Azure Load Testing
- **Monitoring**: Prometheus + Grafana on both environments
- **Alerting**: Azure Monitor integration with on-premises metrics
- **Health Checks**: Multi-environment health endpoints

## Common Tasks
- **Deploy to both environments**: Use multi-environment pipeline
- **Test failover**: Simulate on-premises outage, verify Azure takeover
- **Scale applications**: Horizontal Pod Autoscaler (HPA) configuration
- **Update load balancer**: Modify traffic routing rules
- **Run performance tests**: Execute load tests during deployment

## Integration Points
- **Azure Arc**: On-premises cluster management from Azure
- **GitHub Actions**: CI/CD pipeline orchestration
- **Azure Monitor**: Unified monitoring across environments
- **DNS/Traffic Manager**: Intelligent traffic routing and failover
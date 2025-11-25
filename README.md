# 🐱🐶 Cat vs Dog Voting App - Multi-Cloud Deployment

A Kubernetes-based voting application demonstrating hybrid cloud deployment with Azure Arc on-premises and Azure Kubernetes Service (AKS), featuring automated DevOps pipelines, load balancing, failover, and load testing.

## 🏗️ Architecture

- **On-Premises**: Azure Arc-enabled Kubernetes cluster using AKS Edge Essentials
- **Cloud**: Azure Kubernetes Service (AKS)
- **Load Balancing**: Azure Traffic Manager with priority-based routing
- **Failover**: Automatic failover from on-premises to Azure
- **CI/CD**: GitHub Actions with multi-environment deployment
- **Load Testing**: Artillery.js for performance validation

## 🚀 Quick Start

### Prerequisites

1. **Azure Arc Kubernetes Cluster** (On-Premises)
   ```powershell
   $url = "https://raw.githubusercontent.com/Azure/AKS-Edge/main/tools/scripts/AksEdgeQuickStart/AksEdgeQuickStart.ps1"
   Invoke-WebRequest -Uri $url -OutFile .\AksEdgeQuickStart.ps1
   Unblock-File .\AksEdgeQuickStart.ps1
   ```

2. **Azure AKS Cluster**
   ```bash
   az aks create --resource-group rg-cat-dog-voting --name aks-cat-dog-voting --node-count 3
   ```

3. **GitHub Repository Secrets**
   - `AZURE_CREDENTIALS`: Azure service principal
   - `AZURE_CLIENT_SECRET`: Service principal secret

4. **GitHub Repository Variables**
   - `AZURE_RG`: Azure resource group name
   - `AKS_CLUSTER_NAME`: AKS cluster name
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_TENANT_ID`: Azure tenant ID

### Deployment Options

#### 1. Deploy to Both Environments (Recommended)
```bash
# Trigger via GitHub Actions
gh workflow run deploy-multi-env.yml
```

#### 2. Deploy to Single Environment
```bash
# On-premises only
gh workflow run deploy-single-env.yml -f environment=onprem

# Azure only  
gh workflow run deploy-single-env.yml -f environment=azure
```

#### 3. Manual Deployment (PowerShell)
```powershell
# Deploy to both environments
.\scripts\Deploy-VotingApp.ps1 -Environment both

# Deploy to specific environment
.\scripts\Deploy-VotingApp.ps1 -Environment onprem
.\scripts\Deploy-VotingApp.ps1 -Environment azure
```

## 📊 Load Testing

The pipeline automatically runs load tests after deployment using Artillery.js:

```bash
# Manual load testing
npm install -g artillery@latest
artillery run load-tests/voting-app-load-test.yml --target http://your-app-url
```

Load test includes:
- **Warm-up phase**: 60s at 5 requests/second
- **Ramp-up phase**: 120s at 10 requests/second  
- **Sustained load**: 300s at 15 requests/second
- **Peak load**: 60s at 20 requests/second

## 🔄 Failover Testing

Test the failover mechanism:

1. **Simulate On-Premises Failure**:
   ```bash
   kubectl scale deployment voting-app --replicas=0 --context=arc-cluster
   ```

2. **Verify Azure Takes Over**:
   - Traffic Manager automatically routes to Azure endpoint
   - Monitor via Azure Portal or direct Azure endpoint

3. **Restore On-Premises**:
   ```bash
   kubectl scale deployment voting-app --replicas=3 --context=arc-cluster
   ```

## 🛠️ Project Structure

```
├── .github/workflows/          # GitHub Actions pipelines
│   ├── deploy-multi-env.yml   # Multi-environment deployment
│   └── deploy-single-env.yml  # Single environment deployment
├── k8s/                       # Kubernetes manifests
│   ├── base/                  # Base application manifests
│   ├── onprem/                # On-premises specific configs
│   └── azure/                 # Azure-specific configs
├── app/                       # Python Flask application
│   └── app.py                 # Main application code
├── load-tests/                # Load testing configurations
│   └── voting-app-load-test.yml
├── scripts/                   # Deployment scripts
│   └── Deploy-VotingApp.ps1   # PowerShell deployment script
├── Dockerfile                 # Container image definition
└── requirements.txt           # Python dependencies
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment | `development` |
| `CLUSTER_TYPE` | Kubernetes cluster type | `local` |
| `REDIS_HOST` | Redis host for vote storage | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |

### Kubernetes Resources

- **Deployment**: 3 replicas with auto-scaling (2-10 pods)
- **Service**: LoadBalancer type for external access
- **HPA**: CPU and memory-based scaling
- **Health Checks**: Liveness and readiness probes

## 📈 Monitoring

### Health Endpoints

- `GET /health`: Application health status
- `GET /ready`: Readiness check for Kubernetes

### Metrics

- **Application**: Request count, response time, error rate
- **Infrastructure**: Pod metrics, cluster health
- **Load Balancer**: Traffic distribution, endpoint health

## 🔐 Security

- **Container Security**: Non-root user, minimal base image
- **Network Security**: ClusterIP for internal communication
- **Access Control**: RBAC for Kubernetes resources
- **Secrets Management**: Azure Key Vault integration (optional)

## 🚨 Troubleshooting

### Common Issues

1. **LoadBalancer IP Pending**:
   ```bash
   kubectl get svc voting-app-lb
   # Wait for EXTERNAL-IP assignment
   ```

2. **Pod CrashLoopBackOff**:
   ```bash
   kubectl logs deployment/voting-app
   kubectl describe pod <pod-name>
   ```

3. **Azure Arc Connection Issues**:
   ```bash
   kubectl config get-contexts
   kubectl cluster-info --context=arc-cluster
   ```

4. **Traffic Manager Endpoint Down**:
   ```bash
   az network traffic-manager endpoint show \
     --resource-group rg-cat-dog-voting \
     --profile-name cat-dog-voting-tm \
     --name onprem-endpoint
   ```

### Debug Commands

```bash
# Check deployment status
kubectl get deployments
kubectl rollout status deployment/voting-app

# Check service and endpoints
kubectl get svc
kubectl get endpoints

# Check pod logs
kubectl logs -l app=voting-app

# Check HPA status
kubectl get hpa
```

## 🔄 CI/CD Pipeline Features

- **Multi-environment deployment**: Parallel deployment to on-premises and Azure
- **Container image building**: Automatic Docker image creation and registry push
- **Load balancing setup**: Azure Traffic Manager configuration
- **Automated testing**: Load testing with performance reports
- **Failover simulation**: Automated failover testing
- **Rollback capability**: Kubernetes rollout history and rollback

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Check the troubleshooting section above
- Review the pipeline logs in GitHub Actions
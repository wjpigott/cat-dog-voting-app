# 🐱🐶 Cat vs Dog Voting App - Hybrid Cloud DevOps Pipeline

A complete hybrid cloud demonstration featuring a PostgreSQL-backed voting application deployed across Azure AKS and on-premises Azure Arc-enabled Kubernetes. This project showcases enterprise DevOps practices including database integration, cross-environment analytics, and automated CI/CD pipelines.

## 🏗️ Architecture

- **On-Premises**: Azure Arc-enabled Kubernetes cluster (K3s on Ubuntu)
- **Cloud**: Azure Kubernetes Service (AKS) 
- **Database**: PostgreSQL with cross-environment vote tracking
- **Load Balancing**: Azure Application Gateway with custom port support
- **Failover**: Database-backed resilience with persistent storage
- **CI/CD**: GitHub Actions with GitOps deployment
- **Analytics**: Real-time vote tracking with source attribution (Azure vs On-premises)

## 🚀 Getting Started

### Step 1: Set Up Ubuntu Machine (On-Premises Foundation)

**Start with a standard Ubuntu 22.04 LTS machine** on your local network:

#### Option A: Physical/VM Ubuntu Machine
```bash
# On a fresh Ubuntu 22.04 LTS system
sudo apt update && sudo apt upgrade -y

# Install required tools
sudo apt install -y curl wget git

# Install Docker
sudo apt install docker.io -y
sudo usermod -aG docker $USER
newgrp docker

# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Verify Kubernetes is running
sudo k3s kubectl get nodes
```

#### Option B: Azure VM as "On-Premises"
```bash
# Create Ubuntu VM in Azure (simulating on-premises)
az vm create \
  --resource-group rg-cat-dog-voting-demo \
  --name vm-onprem-k8s \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# SSH into the VM and follow Option A steps above
```

### Step 2: Enable Azure Arc on Your Kubernetes Cluster

**Connect your on-premises Kubernetes cluster to Azure**:

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Install Arc extensions
az extension add --name connectedk8s
az extension add --name k8s-extension

# Connect cluster to Azure Arc
az connectedk8s connect \
  --resource-group rg-cat-dog-voting-demo \
  --name arc-k8s-onprem \
  --location eastus

# Verify Arc connection
az connectedk8s list --resource-group rg-cat-dog-voting-demo
kubectl get pods -n azure-arc
```

### Step 3: Deploy the Cat/Dog Voting Application

**Deploy the database-enhanced voting application**:

```bash
# Clone this repository
git clone https://github.com/wjpigott/cat-dog-voting-app.git
cd cat-dog-voting-app

# Deploy PostgreSQL database
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/postgres-only-deploy.yaml

# Wait for database to be ready
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment

# Download and deploy enhanced voting application
wget -O app/app-with-db.py https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/app/app-with-db.py
wget https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/Dockerfile-enhanced
wget https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/requirements-enhanced.txt

# Create templates directory
mkdir -p templates
wget -O templates/voting.html https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/templates/voting.html

# Build and deploy
docker build -f Dockerfile-enhanced -t voting-app-db:latest .
docker save voting-app-db:latest -o voting-app-db.tar
sudo k3s ctr images import voting-app-db.tar
rm voting-app-db.tar

# Deploy voting application
kubectl create deployment voting-app-onprem --image=voting-app-db:latest
kubectl patch deployment voting-app-onprem -p '{"spec":{"template":{"spec":{"containers":[{"name":"voting-app-db","imagePullPolicy":"Never"}]}}}}'

# Configure database connection
kubectl set env deployment/voting-app-onprem \
    VOTE_SOURCE=onprem \
    DB_HOST=postgres-service \
    DB_PORT=5432 \
    DB_NAME=voting_app \
    DB_USER=votinguser \
    DB_PASSWORD=secure_password_123

# Expose the service
kubectl expose deployment voting-app-onprem --port=80 --target-port=5000 --type=LoadBalancer --name=voting-app-onprem-service
kubectl patch service voting-app-onprem-service --type='json' -p='[{"op":"replace","path":"/spec/ports/0/nodePort","value":31514}]'

# Get your external IP and test
kubectl get svc voting-app-onprem-service
curl http://YOUR-IP:31514/health
```

### Step 4: Set Up Azure AKS (Cloud Environment)

**Create Azure Kubernetes cluster for cloud deployment**:

```bash
# Create AKS cluster
az aks create \
  --resource-group rg-cat-dog-voting-demo \
  --name aks-cat-dog-voting \
  --node-count 3 \
  --enable-managed-identity \
  --generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting

# Deploy voting app that connects to on-premises database
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/azure-voting-app-shared-db.yaml

# Get Azure service external IP
kubectl get svc voting-app-azure-service -w
```

## 🎯 What You'll Have

✅ **Hybrid Cloud Architecture**: On-premises + Azure cloud  
✅ **Azure Arc Management**: On-premises cluster managed via Azure  
✅ **Shared Database**: PostgreSQL with cross-environment vote tracking  
✅ **Real-time Analytics**: See which votes came from Azure vs On-premises  
✅ **Enterprise DevOps**: GitOps deployment from GitHub  
✅ **Load Balancing**: Traffic distribution between environments  
✅ **Persistent Storage**: Votes survive application restarts  

## 🌟 Key Features

- **Cross-Environment Vote Tracking**: See Azure vs On-premises vote sources
- **Database-Backed Persistence**: PostgreSQL with vote history
- **Real-time Web Interface**: Live updates every 5 seconds  
- **REST API**: `/api/results` for programmatic access
- **Health Monitoring**: Built-in health checks and status indicators
- **Visual Analytics**: Environment-specific vote breakdowns

## 💡 Why This Approach?

1. **Realistic Setup**: Starts with standard Ubuntu (like real enterprises)
2. **Progressive Enhancement**: Build → Arc-enable → Deploy application
3. **Hands-on Learning**: Experience real Azure Arc onboarding process
4. **Enterprise Relevance**: Mirrors how organizations adopt hybrid cloud
5. **Complete Pipeline**: From infrastructure to application deployment

## 📊 Testing Your Deployment

### Verify Both Environments
```bash
# Test on-premises deployment
curl http://YOUR-ONPREM-IP:31514/health
curl http://YOUR-ONPREM-IP:31514/api/results

# Test Azure deployment  
curl http://YOUR-AZURE-IP/health
curl http://YOUR-AZURE-IP/api/results
```

### Cast Some Votes
Visit both environments in your browser:
- **On-Premises**: `http://YOUR-ONPREM-IP:31514`
- **Azure Cloud**: `http://YOUR-AZURE-IP`

Vote for cats and dogs from both environments and watch the analytics!

### Verify Cross-Environment Analytics
```bash
# Check the database shows votes from both sources
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app -c "SELECT vote_option, source, COUNT(*) FROM votes GROUP BY vote_option, source ORDER BY vote_option, source;"
```

You should see results like:
```
 vote_option | source  | count 
-------------+---------+-------
 cat         | azure   |     3
 cat         | onprem  |     2
 dog         | azure   |     1
 dog         | onprem  |     4
```

## 🔄 Advanced Operations

### Load Testing
```bash
# Install Artillery.js
npm install -g artillery@latest

# Run load tests
artillery run load-tests/voting-app-load-test.yml --target http://YOUR-ONPREM-IP:31514
```

### Failover Testing
```bash
# Scale down on-premises to simulate failure
kubectl scale deployment voting-app-onprem --replicas=0

# Votes now only go to Azure environment
# Check database to see only "azure" source votes

# Restore on-premises
kubectl scale deployment voting-app-onprem --replicas=1
```

### Monitoring and Observability
```bash
# Check application logs
kubectl logs deployment/voting-app-onprem -f

# Monitor database connections
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"
```

## 🛠️ Development Workflow

### Local Development
```bash
# Run locally with Docker Compose
docker-compose up -d postgres
docker build -f Dockerfile-enhanced -t voting-app-local .
docker run -e DB_HOST=localhost -p 5000:5000 voting-app-local
```

### Making Changes
```bash
# Update the application
# Edit app/app-with-db.py or templates/voting.html

# Rebuild and redeploy
docker build -f Dockerfile-enhanced -t voting-app-db:latest .
docker save voting-app-db:latest -o voting-app-db.tar
sudo k3s ctr images import voting-app-db.tar
kubectl rollout restart deployment/voting-app-onprem
```

## 🗃️ Database Schema

The PostgreSQL database includes:

```sql
-- Votes table with source attribution
CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    vote_option VARCHAR(10) NOT NULL CHECK (vote_option IN ('cat', 'dog')),
    source VARCHAR(50) NOT NULL,  -- 'azure' or 'onprem'
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_votes_option ON votes(vote_option);
CREATE INDEX idx_votes_source ON votes(source);
```

## 🏆 Project Features Demonstrated

✅ **Hybrid Cloud Architecture**: Azure Arc + AKS integration  
✅ **Database Integration**: PostgreSQL with persistent storage  
✅ **Cross-Environment Analytics**: Vote source tracking  
✅ **Container Orchestration**: Kubernetes deployment patterns  
✅ **DevOps Automation**: Infrastructure as Code  
✅ **Real-time Monitoring**: Health checks and status endpoints  
✅ **Load Balancing**: Traffic distribution strategies  
✅ **Disaster Recovery**: Database-backed failover scenarios  

## 📋 Troubleshooting

### Common Issues

**Database Connection Failed**
```bash
# Check if PostgreSQL is running
kubectl get pods -l app=postgres

# Check database logs
kubectl logs deployment/postgres-deployment

# Test connection manually
kubectl exec -it deployment/postgres-deployment -- psql -U votinguser -d voting_app -c "SELECT 1;"
```

**Application Won't Start**
```bash
# Check application logs
kubectl logs deployment/voting-app-onprem

# Verify environment variables
kubectl describe deployment voting-app-onprem | grep -A 10 Environment
```

**Can't Access Application**
```bash
# Check service configuration
kubectl get svc voting-app-onprem-service

# Verify firewall/ports
sudo ufw status
sudo netstat -tlnp | grep 31514
```

### Resource Requirements

**Minimum System Requirements**:
- CPU: 2 cores  
- RAM: 4GB  
- Disk: 20GB available  
- Network: Internet connectivity for Azure Arc

**Recommended for Production**:
- CPU: 4+ cores
- RAM: 8GB+  
- Disk: 50GB+ with SSD
- Network: Stable connectivity with monitoring

## 🎓 Learning Outcomes

After completing this project, you'll understand:

1. **Azure Arc**: How to connect on-premises Kubernetes to Azure
2. **Hybrid Cloud**: Managing workloads across environments  
3. **Database Integration**: Persistent storage with Kubernetes
4. **DevOps Pipelines**: Automated deployment workflows
5. **Container Orchestration**: Kubernetes deployment patterns
6. **Monitoring**: Application and infrastructure observability
7. **Load Testing**: Performance validation techniques
8. **Disaster Recovery**: Failover and backup strategies

## 📚 Additional Resources

- [Azure Arc Documentation](https://docs.microsoft.com/azure/azure-arc/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)  
- [PostgreSQL on Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/postgresql/)
- [Flask Web Development](https://flask.palletsprojects.com/)
- [Docker Best Practices](https://docs.docker.com/develop/best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome-feature`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to the branch (`git push origin feature/awesome-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Azure Arc team for hybrid cloud capabilities
- Kubernetes community for container orchestration
- PostgreSQL team for robust database foundation  
- Flask community for web framework excellence

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
# Azure AKS Quick Health Check

## 🔍 Is Azure AKS Running?

Run these commands to check your Azure AKS cluster status:

### Check AKS Cluster Status
```bash
# Check if AKS cluster is running
az aks show --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting --query "powerState.code"

# Start AKS if stopped
az aks start --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting
```

### Check Voting App Deployment
```bash
# Get AKS credentials 
az aks get-credentials --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting

# Check if voting app is running
kubectl get pods
kubectl get services

# Check LoadBalancer external IP
kubectl get service --all-namespaces | grep LoadBalancer
```

### Test Public IP Connectivity
```bash
# Test the public IPs we found
curl -v http://52.154.54.110/
curl -v http://52.154.54.110:8080/
curl -v http://catdog-lb-simple.centralus.cloudapp.azure.com/

# Test with timeout
curl --connect-timeout 10 http://52.154.54.110/health
```

## 🚀 If Azure AKS is Down - Quick Redeploy

```bash
# Start AKS cluster
az aks start --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting

# Redeploy voting app
kubectl apply -f https://raw.githubusercontent.com/wjpigott/cat-dog-voting-app/main/cross-environment-voting-azure.yaml

# Wait and check service
kubectl get service voting-app-service --watch
```

## 🎯 Expected Working State

When Azure is healthy:
- AKS cluster status: "Running"  
- Voting app pod: 1/1 Ready
- LoadBalancer service: Has external IP
- `curl http://52.154.54.110/health` returns: `{"status":"healthy"}`

**Question**: Can you run `az aks show --resource-group rg-cat-dog-voting --name aks-cat-dog-voting --query "powerState.code"` to check if your AKS cluster is running?
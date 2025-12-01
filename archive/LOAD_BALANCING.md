# 🔄 Load Balancing & Failover Guide

## Current Architecture: High Availability with Automatic Failover

The Cat vs Dog Voting App now includes **automatic load balancing and failover** between Azure AKS and on-premises environments.

### 🎯 **Load Balanced Endpoint**
- **Primary URL**: http://172.168.251.177 (your load balancer IP)
- **Automatic Failover**: Yes ✅
- **Health Monitoring**: Every 30 seconds ✅  
- **Zero Downtime**: Traffic automatically routes to healthy backend ✅

### 🏗️ **Architecture Overview**

```
                    🌐 Internet Traffic
                           │
                           ▼
               ┌─────────────────────────────┐
               │     NGINX Load Balancer     │
               │    (172.168.251.177)       │
               │   Health Checks + Failover  │
               └─────────────┬───────────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
          ┌─────────────────┐  ┌─────────────────┐
          │   🔷 Azure AKS  │  │  🏠 OnPrem K3s  │
          │ 52.154.54.110   │  │ 66.242.207.21   │
          │   Primary       │  │    Backup       │
          │  (Weight: 3)    │  │  (Weight: 1)    │
          └─────────────────┘  └─────────────────┘
                    │                   │
                    ▼                   ▼
          ┌─────────────────┐  ┌─────────────────┐
          │ Azure PostgreSQL│  │ OnPrem Database │
          │ 6🐱, 3🐶        │  │ 12🐱, 8🐶      │
          └─────────────────┘  └─────────────────┘
```

### ⚖️ **Load Balancing Strategy**

**Traffic Distribution:**
- **75%** → Azure AKS (Primary, Weight: 3)
- **25%** → OnPrem K3s (Backup, Weight: 1)

**Failover Behavior:**
- If Azure fails → 100% traffic to OnPrem
- If OnPrem fails → 100% traffic to Azure  
- If both fail → Load balancer returns 503 error

### ❤️ **Health Monitoring**

**Health Check Frequency:** Every 30 seconds
**Failure Threshold:** 2 consecutive failures = backend marked down
**Recovery:** Automatic when backend becomes healthy

**Endpoints Monitored:**
```bash
# Azure backend health
curl http://52.154.54.110/health

# OnPrem backend health  
curl http://66.242.207.21:31514/health

# Load balancer health
curl http://172.168.251.177/health
```

### 🚀 **Deployment**

```bash
# Deploy the load balancer
kubectl apply -f load-balancer-simple.yaml

# Get load balancer IP
kubectl get service voting-load-balancer-service

# Test failover functionality
./scripts/test-failover.sh
```

### 🧪 **Testing Failover**

**Simulate Azure Failure:**
```bash
# Stop Azure deployment
kubectl delete deployment azure-voting-app-complete

# Test - should automatically use OnPrem only
curl http://172.168.251.177/api/results

# Restore Azure
kubectl apply -f azure-voting-app-complete.yaml
```

**Simulate OnPrem Failure:**
```bash
# Test with OnPrem down (simulate network issue)
# Load balancer will automatically use Azure only
curl http://172.168.251.177/api/results
```

### 📊 **Monitoring & Status**

**Check Load Balancer Status:**
```bash
# Load balancer health  
curl http://172.168.251.177/health

# Backend status
curl http://172.168.251.177/lb-status

# Full failover test
./scripts/test-failover.sh
```

**Check Individual Backends:**
```bash
# Azure direct
curl http://52.154.54.110/api/results

# OnPrem direct  
curl http://66.242.207.21:31514/api/results

# Load balanced (recommended)
curl http://172.168.251.177/api/results
```

### 🎯 **Benefits**

✅ **High Availability**: Service remains available even if one environment fails  
✅ **Automatic Recovery**: No manual intervention needed for failover/recovery  
✅ **Load Distribution**: Spreads traffic across both environments  
✅ **Health Monitoring**: Continuous monitoring of backend health  
✅ **Zero Configuration**: Works out of the box with existing deployments  

### 🔧 **Configuration**

Update `config/customer.env` with your load balancer IP:
```bash
LOAD_BALANCED_ENDPOINT="http://YOUR_LOAD_BALANCER_IP"
ENABLE_FAILOVER="true"
```

---

**Result: Your voting app now has enterprise-grade high availability with automatic failover!** 🚀
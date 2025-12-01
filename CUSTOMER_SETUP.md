# 🛠️ Customer Setup Guide

## Quick Start for Your Environment

This guide helps you customize the Cat vs Dog Voting App for your specific infrastructure.

### ⚠️ **IMPORTANT: Port Planning**

**Before deploying, plan your port strategy to avoid Traffic Manager issues:**

```bash
# Recommended: Use port 80 on both environments
AZURE_SERVICE_PORT=80      # LoadBalancer external port
ONPREM_SERVICE_PORT=80     # NodePort external port (e.g., 30080)

# Alternative: Use same custom port on both
AZURE_SERVICE_PORT=31514   # NodePort to match OnPrem
ONPREM_SERVICE_PORT=31514  # Existing NodePort
```

**Traffic Manager requires identical ports on all endpoints!**

### ✅ Step 1: Configure Your Environment

Copy and customize the configuration file:

```bash
# Copy the template
cp config/customer.env.template config/customer.env

# Edit with your specific values
nano config/customer.env
```

### 🔧 Required Configuration

Edit `config/customer.env` with your values:

```bash
# Your on-premises Kubernetes cluster
ONPREM_ENDPOINT="http://YOUR_ONPREM_IP:31514"      # Use port 31514 (working configuration)
ONPREM_PUBLIC_IP="YOUR_ONPREM_IP"
ONPREM_SERVICE_PORT=31514                           # NodePort for external access

# Your Azure AKS cluster  
AZURE_ENDPOINT="http://YOUR_AZURE_IP:31514"        # Use port 31514 (matches OnPrem)
AZURE_SERVICE_PORT=31514                            # LoadBalancer external port

# Your Azure PostgreSQL server
AZURE_POSTGRES_HOST="your-postgres-server.postgres.database.azure.com"
AZURE_POSTGRES_USER="your-username"
AZURE_POSTGRES_PASSWORD="your-password"
AZURE_POSTGRES_DB="postgres"

# Your Azure AKS (will be auto-assigned, but check these)
AZURE_LOAD_BALANCER_IP="YOUR_AZURE_LB_IP"
AZURE_CLUSTER_NAME="your-aks-cluster"
```

### 🚀 Step 2: Deploy

Once configured, deployment is simple:

```bash
# Deploy Azure environment (uses your config)
./scripts/deploy-azure.sh

# Deploy on-premises environment (uses your config)
./scripts/deploy-onprem.sh

# Verify both environments work
./scripts/verify-environments.sh
```

### 🔍 Step 3: Verify

Your applications should be accessible at:
- **Azure**: `http://YOUR_AZURE_LB_IP`
- **OnPrem**: `http://YOUR_ONPREM_IP:31514`

Both should show combined vote totals from both environments.

### 📋 Pre-Deployment Checklist

- [ ] Azure PostgreSQL server created and accessible
- [ ] Azure AKS cluster running
- [ ] On-premises Kubernetes cluster running 
- [ ] Network connectivity between Azure and on-premises
- [ ] PostgreSQL firewall rules allow connections
- [ ] Configuration file updated with your values

### 🆘 Troubleshooting

If deployments fail, check:

1. **Network connectivity**: Can Azure reach your on-premises IP?
2. **Database access**: Are PostgreSQL credentials correct?
3. **Firewall rules**: Is your IP allowed to access Azure PostgreSQL?
4. **Service ports**: Is port 31514 open on your on-premises cluster?

### 📞 Support

For issues:
1. Check configuration in `config/customer.env`
2. Run `./scripts/verify-environments.sh` for diagnostic info
3. Check Kubernetes logs: `kubectl logs -l app=azure-voting-app-complete`

---

**Note**: This setup creates a secure, cross-environment application. Ensure your network security policies allow the required communications between Azure and on-premises.
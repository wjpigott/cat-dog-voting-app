# Quick Azure PostgreSQL Setup - Manual Portal Method

Since Azure CLI has permission issues, here's the fastest way via Azure Portal:

## 1. Create PostgreSQL Database (2 minutes via Portal)

**Go to Azure Portal: https://portal.azure.com**

1. **Create Resource** → Search "PostgreSQL" → **Azure Database for PostgreSQL Flexible Server**

2. **Basic Settings:**
   - Resource Group: `rg-cat-dog-voting-demo`
   - Server name: `postgres-cat-dog-voting`
   - Region: `East US`
   - PostgreSQL version: `14`
   - Workload type: `Development` (cheapest)

3. **Authentication:**
   - Username: `votinguser`
   - Password: `SecureVotingPassword123!`

4. **Networking:**
   - ✅ Allow public access from any Azure service
   - ✅ Add current client IP address

5. **Click Review + Create** → **Create**

## 2. Set up Database Schema (1 minute)

Once created, get the server name from the Overview page (something like `postgres-cat-dog-voting.postgres.database.azure.com`)

**Run these commands:**
```bash
# Connect and create schema
psql "postgresql://votinguser:SecureVotingPassword123!@postgres-cat-dog-voting.postgres.database.azure.com:5432/postgres?sslmode=require"

# In psql:
CREATE DATABASE voting_app;
\c voting_app;

CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    vote_option VARCHAR(10) NOT NULL CHECK (vote_option IN ('cat', 'dog')),
    source VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_votes_option ON votes(vote_option);
CREATE INDEX idx_votes_source ON votes(source);

\q
```

## 3. Quick Deployment YAML

Here's the Azure deployment that connects to Azure PostgreSQL:

```yaml
# azure-voting-app-with-azure-db.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-app-azure
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-app-azure
  template:
    metadata:
      labels:
        app: voting-app-azure
    spec:
      containers:
      - name: voting-app
        image: ghcr.io/wjpigott/voting-app-db:latest
        ports:
        - containerPort: 5000
        env:
        - name: VOTE_SOURCE
          value: "azure"
        - name: DB_HOST
          value: "postgres-cat-dog-voting.postgres.database.azure.com"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "voting_app"
        - name: DB_USER
          value: "votinguser"
        - name: DB_PASSWORD
          value: "SecureVotingPassword123!"
---
apiVersion: v1
kind: Service
metadata:
  name: voting-app-azure-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: voting-app-azure
```

## 4. Deploy to Azure AKS

```bash
# Get AKS credentials (if not already done)
az aks get-credentials --resource-group rg-cat-dog-voting-demo --name aks-cat-dog-voting

# Deploy
kubectl apply -f azure-voting-app-with-azure-db.yaml

# Get external IP
kubectl get svc voting-app-azure-service
```

**Total time: ~5 minutes** ⏱️

This creates:
- ✅ Cheap Azure PostgreSQL (~$15/month)
- ✅ Azure votes go to Azure DB
- ✅ On-premises votes stay local
- ✅ Cross-environment analytics
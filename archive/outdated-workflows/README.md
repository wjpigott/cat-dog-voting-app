# Outdated GitHub Actions Workflows Archive

This directory contains GitHub Actions workflows that are **no longer needed** with the current deployment strategy.

## Current Working Workflows (Active)

**💰 Cost Optimization**: All workflows use `workflow_dispatch` (manual trigger only) to prevent automatic Azure resource consumption when environments are shut down to save costs.

### 🚀 Primary Workflows
- **[deploy-multi-env.yml](../../.github/workflows/deploy-multi-env.yml)** - **MAIN DEPLOYMENT**
  - Deploys to both Azure AKS and OnPrem Arc clusters
  - Configures Azure Traffic Manager for failover
  - Includes load testing
  - **Trigger**: Manual only (`workflow_dispatch`)
  - **Use this for production deployments**

### 🛠️ Supporting Workflows  
- **[deploy-postgres.yml](../../.github/workflows/deploy-postgres.yml)** - Database setup
  - Creates Azure PostgreSQL instance
  - Configures database connectivity
  - **Trigger**: Manual only (`workflow_dispatch`)
  - **Run this once for initial setup**

- **[deploy-single-env.yml](../../.github/workflows/deploy-single-env.yml)** - Single environment utility
  - Deploy to just Azure OR just OnPrem
  - Useful for testing individual environments
  - **Trigger**: Manual only (`workflow_dispatch`)
  - **Use for targeted deployments**

## Archived Workflows (Outdated)

### clean-deploy-azure.yml
- **Purpose**: Clean deployment to Azure AKS only
- **Why Archived**: Duplicate functionality, covered by deploy-single-env.yml
- **Replacement**: Use `deploy-single-env.yml` with `environment: azure`

### deploy-azure-only.yml
- **Purpose**: Azure-only deployment 
- **Why Archived**: Duplicate functionality, not aligned with multi-env strategy
- **Replacement**: Use `deploy-single-env.yml` with `environment: azure`

### final-deploy.yml  
- **Purpose**: Unclear "final" deployment
- **Why Archived**: Ambiguous naming, functionality unclear
- **Replacement**: Use `deploy-multi-env.yml` for complete deployments

### quick-deploy-azure.yml
- **Purpose**: Quick Azure deployment
- **Why Archived**: Multiple Azure-only workflows create confusion
- **Replacement**: Use `deploy-single-env.yml` with `environment: azure`

## Migration Notes

### Previous Approach Issues:
1. **Too many similar workflows** - Confusing which one to use
2. **Inconsistent naming** - "final", "quick", "clean" unclear
3. **Duplicate functionality** - Multiple ways to do same thing

### Current Streamlined Approach:
1. **One primary workflow** - `deploy-multi-env.yml` for production
2. **Clear utility workflows** - Specific purposes (database, single-env)
3. **Consistent naming** - Purpose-based naming convention

## Usage Recommendations

### 🎯 For New Deployments:
```bash
# Complete multi-environment deployment with Traffic Manager
gh workflow run deploy-multi-env.yml

# Set up database (one-time setup)
gh workflow run deploy-postgres.yml

# Test individual environment
gh workflow run deploy-single-env.yml -f environment=azure
gh workflow run deploy-single-env.yml -f environment=onprem
```

### 📖 See Current Documentation:
- [WORKING_CONFIGURATION.md](../../WORKING_CONFIGURATION.md) - Current setup
- [README.md](../../README.md) - Main documentation
- [CUSTOMER_SETUP.md](../../CUSTOMER_SETUP.md) - Setup guide
# Archived Troubleshooting Scripts

This folder contains troubleshooting and debugging scripts that were used during the initial setup and configuration of the project. These scripts are kept for historical reference but are not needed for normal operations.

## Why These Scripts Were Archived

These scripts were created to solve specific issues during development:
- Port configuration troubleshooting
- Traffic Manager endpoint updates
- Service health proxy deployments
- Various deployment fixes and alternatives

## Active Scripts

For current deployment and monitoring, use the scripts in the parent `scripts/` folder:
- `deploy-azure.sh` - Deploy to Azure AKS
- `deploy-onprem.sh` - Deploy to on-premises cluster
- `verify-environments.sh` - Verify both environments
- `test-deployment.sh` - Test deployment status
- `test-failover.sh` - Test Traffic Manager failover
- `monitor-endpoints.ps1` - Monitor endpoint health
- `monitor-traffic-manager.ps1` - Monitor Traffic Manager status

## Archived Script Categories

### Traffic Manager Configuration
- `deploy-traffic-manager.ps1` / `.sh`
- `deploy-traffic-manager-alternative.ps1`
- `deploy-traffic-manager-fixed.ps1`
- `update-traffic-manager-powershell.ps1`

### Traffic Manager Troubleshooting
- `fix-traffic-manager-and-cleanup.ps1`
- `fix-traffic-manager-port-31514.ps1`
- `fix-traffic-manager-tcp-monitoring.ps1`
- `fix-traffic-manager-use-port80.ps1`
- `quick-fix-traffic-manager.ps1`
- `troubleshoot-port-31514.ps1`

### Port Configuration
- `azure-port-fix-commands.ps1`
- `complete-azure-port-standardization.ps1`
- `fix-port-consistency.ps1`
- `fix-k3s-service-port80.sh`

### Health Proxy Deployments
- `deploy-onprem-health-proxy.ps1`
- `deploy-onprem-health-proxy-remote.ps1`
- `deploy-onprem-health-proxy-linux.sh`
- `deploy-onprem-port80-proxy.ps1`

### Failover Testing Variants
- `test-failover-analysis.ps1`
- `test-failover-tm.sh`
- `Test-Failover.ps1`

### Other
- `DEPLOY-GUIDE.ps1` - Deployment walkthrough script

## Note

These scripts may contain environment-specific details or outdated configurations. They are preserved for reference but should not be used without review and updates.

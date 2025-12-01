# Outdated Proxy Configurations Archive

This directory contains proxy configuration files that are **no longer needed** with the current Traffic Manager setup.

## Current Working Setup (No Proxy Needed)
- **Traffic Manager**: TCP monitoring on port 31514
- **Azure**: LoadBalancer service on port 31514
- **OnPrem**: NodePort service on port 31514
- **Monitoring**: Simple TCP health checks

## Archived Files (Outdated Approaches)

### onprem-proxy-port80.yaml
- **Purpose**: NGINX proxy for HTTP monitoring on port 80
- **Why Archived**: Current setup uses TCP monitoring, no proxy needed
- **Alternative**: Direct TCP monitoring on port 31514

### voting-proxy-8080.yaml
- **Purpose**: NGINX proxy for port 8080 access
- **Why Archived**: Inconsistent with current port 31514 standardization
- **Alternative**: Direct access on port 31514

### traffic-manager-health-proxy.yaml
- **Purpose**: Health check proxy for Traffic Manager HTTP monitoring
- **Why Archived**: TCP monitoring is simpler and more reliable
- **Alternative**: TCP monitoring on port 31514

## Migration Notes
These files were part of earlier approaches that required:
1. HTTP health check endpoints
2. Port translation between environments
3. Complex proxy configurations

The current approach eliminates this complexity by:
1. Using TCP monitoring (no health endpoint needed)
2. Standardizing both environments on port 31514
3. Direct service access without proxies

## See Current Documentation
- [WORKING_CONFIGURATION.md](../../WORKING_CONFIGURATION.md) - Current setup
- [README.md](../../README.md) - Main documentation
- [TRAFFIC_MANAGER_BEST_PRACTICES.md](../../TRAFFIC_MANAGER_BEST_PRACTICES.md) - Best practices
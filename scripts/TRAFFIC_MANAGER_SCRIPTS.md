# Traffic Manager Scripts - Current Inventory

## 🎯 Essential Working Scripts

### Main Deployment
- **`deploy-traffic-manager-alternative.ps1`** - Main Traffic Manager deployment script (✅ WORKING)
- **`deploy-traffic-manager-fixed.ps1`** - Alternative deployment with fixes (✅ WORKING)

### Configuration & Testing  
- **`complete-azure-port-standardization.ps1`** - Complete Azure port fix (✅ USED TODAY)
- **`azure-port-fix-commands.ps1`** - Quick commands reference (✅ USED TODAY)
- **`fix-traffic-manager-tcp-monitoring.ps1`** - Switch to TCP monitoring (✅ WORKING)
- **`test-failover-analysis.ps1`** - Test failover functionality (✅ WORKING)

### Monitoring & Maintenance
- **`monitor-traffic-manager.ps1`** - Monitor Traffic Manager health (✅ WORKING)

## 🗂️ Archived Scripts (Outdated/Redundant)

Moved to `scripts/archive-traffic-manager-fixes/`:
- `deploy-traffic-manager-direct.ps1` - Superseded by alternative script
- `deploy-traffic-manager-manual.ps1` - Replaced by automated scripts  
- `deploy-traffic-manager-quick.ps1` - Merged into main scripts
- `deploy-traffic-manager-rest.ps1` - REST API approach, not needed
- `fix-traffic-manager-failover.ps1` - Fixed by port standardization
- `fix-traffic-manager-monitoring.ps1` - TCP monitoring now working
- `fix-traffic-manager-ports.ps1` - Completed successfully

## 🎯 Working Configuration Commands

### Deploy Traffic Manager
```powershell
# Main deployment (recommended)
.\scripts\deploy-traffic-manager-alternative.ps1

# Alternative deployment  
.\scripts\deploy-traffic-manager-fixed.ps1
```

### Configure Port Consistency
```powershell
# Fix Azure to match OnPrem port 31514
.\scripts\complete-azure-port-standardization.ps1

# Switch to TCP monitoring
.\scripts\fix-traffic-manager-tcp-monitoring.ps1
```

### Test & Monitor
```powershell
# Test failover functionality
.\scripts\test-failover-analysis.ps1

# Monitor Traffic Manager health
.\scripts\monitor-traffic-manager.ps1
```

## 📋 Script Dependencies

All scripts require:
- Azure PowerShell modules (Az.TrafficManager, Az.Profile)
- kubectl.exe in current directory
- Valid Azure subscription and authentication

## 🎯 Success Criteria

✅ **Working Traffic Manager URL:** `http://<traffic-manager-url>:31514`  
✅ **Both endpoints on port 31514:** Azure and OnPrem consistent  
✅ **TCP monitoring:** Simple and reliable  
✅ **Automatic failover:** Tested and confirmed working  

## 🔧 Maintenance Notes

- **Port 31514** is the standardized port for both environments
- **TCP monitoring** on port 31514 works reliably
- **Router port 80** remains available for management
- **LoadBalancer service** created for Azure on port 31514
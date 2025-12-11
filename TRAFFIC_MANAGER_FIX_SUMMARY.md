# 🔧 Traffic Manager Fix Summary - December 5, 2025

## 🎯 Current Situation

After restarting your AKS cluster, you have **multiple services** running, which is causing confusion:

### Services in Azure AKS:

| IP Address | Port | Service Name | Status | Notes |
|------------|------|--------------|--------|-------|
| **<azure-ip-1>** | **80** | azure-voting-app-complete-service | ✅ **ONLINE** | **BETTER VERSION - USE THIS** |
| <azure-ip-2> | 80 | voting-load-balancer-service | ❌ Offline | **OLD - DELETE THIS** |
| <azure-ip-3> | 31514 | voting-app-31514-lb | ❌ Offline | For Traffic Manager compatibility |

### OnPrem:
| IP Address | Port | Status |
|------------|------|--------|
| **YOUR_ONPREM_IP** | **31514** | ✅ **ONLINE** |

---

## ⚠️ The Problem

**Traffic Manager requires all endpoints to use the SAME PORT.**

Currently:
- **Azure best version**: Port **80** ✅
- **OnPrem**: Port **31514** ❌

This is why Traffic Manager isn't working - the ports don't match!

---

## ✅ Solution: Two Options

### **OPTION A: Use Port 80 Everywhere (RECOMMENDED)**

This is the standard HTTP port and best practice.

#### Steps:

**1. Clean up old Azure service:**
```bash
kubectl delete service voting-load-balancer-service
kubectl delete deployment voting-load-balancer
```

**2. Azure is already on port 80:** ✅
- Service: `azure-voting-app-complete-service`
- IP: `<azure-ip>:80`

**3. Change OnPrem to port 80:**

On your **OnPrem K3s cluster**, you'll need to either:

**Option 3a: Use NodePort 30080 and router forwarding**
```bash
# On OnPrem K3s
kubectl patch service <your-voting-service-name> --type='json' \
  -p='[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080}]'

# Then configure your router to forward:
# External Port 80 → OnPrem IP:30080
```

**Option 3b: Try NodePort 80** (may not work on all systems)
```bash
# On OnPrem K3s
kubectl patch service <your-voting-service-name> --type='json' \
  -p='[{"op":"replace","path":"/spec/ports/0/nodePort","value":80}]'
```

**4. Update Traffic Manager:**
```powershell
# Run from this repo
.\scripts\update-traffic-manager-powershell.ps1 `
  -AzureIP "<azure-ip>" `
  -OnPremIP "$env:ONPREM_PUBLIC_IP" `
  -Port 80 `
  -Protocol "HTTP"
```

**Result:**
- Traffic Manager URL: `http://<traffic-manager-url>`
- Standard HTTP port (no port number needed in URL)
- Better monitoring with HTTP health checks

---

### **OPTION B: Use Port 31514 Everywhere (EASIER)**

Keep OnPrem as-is and change Azure to match.

#### Steps:

**1. Clean up old Azure service:**
```bash
kubectl delete service voting-load-balancer-service
kubectl delete deployment voting-load-balancer
```

**2. Test if port 31514 service works:**
```bash
# First check if the service is actually running
kubectl get pods -l app=azure-voting-app-complete

# If pods are running but service is offline, restart:
kubectl rollout restart deployment azure-voting-app-complete
```

**3. OnPrem stays the same:** ✅
- Already on port 31514

**4. Update Traffic Manager:**
```powershell
# Run from this repo
.\scripts\update-traffic-manager-powershell.ps1 `
  -AzureIP "<azure-ip>" `
  -OnPremIP "$env:ONPREM_PUBLIC_IP" `
  -Port 31514 `
  -Protocol "TCP"
```

**Result:**
- Traffic Manager URL: `http://<traffic-manager-url>:31514`
- No OnPrem changes needed
- Simpler TCP monitoring

---

## 🚀 Quick Start - Execute the Fix

### Step 1: Clean Up Old Service (Both Options)

```powershell
# Using kubectl from your repo
cd c:\repos\SQLAIChat\sqlaichat
.\kubectl-temp.exe delete service voting-load-balancer-service
.\kubectl-temp.exe delete deployment voting-load-balancer
```

### Step 2A: For Port 80 Option

1. Change OnPrem to port 80 (see Option A step 3 above)
2. Run Traffic Manager update:
```powershell
.\scripts\update-traffic-manager-powershell.ps1 -AzureIP "<azure-ip>" -OnPremIP "$env:ONPREM_PUBLIC_IP" -Port 80 -Protocol "HTTP"
```

### Step 2B: For Port 31514 Option (RECOMMENDED - Easier)

1. Check Azure service:
```powershell
.\kubectl-temp.exe get pods -l app=azure-voting-app-complete
# If pods show "Running", the service should work
```

2. Run Traffic Manager update:
```powershell
.\scripts\update-traffic-manager-powershell.ps1 -AzureIP "<azure-ip>" -OnPremIP "$env:ONPREM_PUBLIC_IP" -Port 31514 -Protocol "TCP"
```

---

## 🔍 Why Port 31514 Service Shows Offline

The service `voting-app-31514-lb (<azure-ip>:31514)` showed offline in the test, but this might be because:

1. **Azure was just restarted** - LoadBalancer IPs take time to stabilize
2. **Health endpoint might be on different path** - HTTP test might fail but TCP would work
3. **Pods might still be starting** - Check with: `kubectl get pods`

**Recommendation:** Try **Option B** first since it requires no OnPrem changes and the service configuration already exists.

---

## 📋 Verification Commands

After making changes:

```powershell
# Check Azure services
.\kubectl-temp.exe get services

# Check pods are running
.\kubectl-temp.exe get pods

# Test endpoints directly
Invoke-WebRequest -Uri "http://<azure-ip>" -Method Head
Invoke-WebRequest -Uri "http://$env:ONPREM_PUBLIC_IP:31514" -Method Head

# Test Traffic Manager (after update)
Invoke-WebRequest -Uri "http://<traffic-manager-url>:31514" -Method Head
```

---

## 🎯 Recommended Action Plan

**I recommend Option B (Port 31514) because:**
1. ✅ No OnPrem changes needed
2. ✅ Service already exists in Azure
3. ✅ Matches your working configuration from before
4. ✅ Less complexity

**Do this now:**

1. Delete old load balancer service
2. Verify Azure pods are running
3. Update Traffic Manager to use port 31514 on both endpoints
4. Test Traffic Manager URL

---

## 📞 Need Help?

If you run into issues:

1. **Azure CLI permission errors**: Use the PowerShell scripts instead (they use Az module)
2. **Service won't start**: Check pod logs with `kubectl logs <pod-name>`
3. **Traffic Manager not updating**: Use Azure Portal as backup:
   - Go to https://portal.azure.com
   - Find Traffic Manager: `<traffic-manager-name>`
   - Manually update endpoints and monitoring port

---

**Summary:** You have multiple Azure services running. Delete the old one, pick a consistent port for both environments, and update Traffic Manager to match. Option B (port 31514) is easiest!

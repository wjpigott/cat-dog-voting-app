# AKS Edge Essentials Disk Extension Commands
# Run these commands in an Administrator PowerShell session

# 1. Check current AKS Edge configuration
Import-Module AksEdge
Get-AksEdgeNodeAddr

# 2. Stop the AKS Edge deployment safely
Stop-AksEdgeDeployment

# 3. Extend the Linux VM disk size (add 30GB)
# Note: Adjust the path and VM name based on your setup
$vmName = "AKS-Edge-Linux-VM"  # Adjust this name
$currentDiskPath = "C:\AKS-Edge\$vmName.vhdx"  # Adjust path as needed

# Resize the VHDX file to add 30GB
Resize-VHD -Path $currentDiskPath -SizeBytes ((Get-VHD -Path $currentDiskPath).Size + 30GB)

# 4. Restart AKS Edge
Start-AksEdgeDeployment

# 5. Connect to the Linux node and extend the filesystem
# Get the node IP
$nodeIP = Get-AksEdgeNodeAddr

# SSH to extend the filesystem (you'll need to run these inside the Linux VM)
Write-Host "Connect to the Linux node at $nodeIP and run the following commands:"
Write-Host "sudo growpart /dev/sda 1"
Write-Host "sudo resize2fs /dev/sda1"
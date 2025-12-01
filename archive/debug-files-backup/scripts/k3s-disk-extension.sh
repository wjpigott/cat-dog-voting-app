#!/bin/bash
# K3s Disk Extension Script
# Run this script on your Ubuntu system running K3s

echo "🔍 Checking current disk usage..."

# Check current disk usage
df -h

echo ""
echo "🔍 Checking K3s specific directories..."

# Check K3s data directory usage
sudo du -sh /var/lib/rancher/k3s/
sudo du -sh /var/lib/containerd/ 2>/dev/null || echo "containerd directory not found"

echo ""
echo "🔍 Checking container images..."

# Check container image usage
sudo crictl images | head -20

echo ""
echo "==================================="
echo "🚀 DISK EXTENSION OPTIONS"
echo "==================================="

echo ""
echo "Option 1: Clean up unused resources (Quick fix)"
echo "--------------------------------------------"
echo "sudo crictl rmi --prune                    # Remove unused images"
echo "sudo systemctl restart k3s                 # Restart K3s"
echo "sudo journalctl --vacuum-time=2d           # Clean old logs"
echo ""

echo "Option 2: Extend the underlying disk (if VM)"
echo "--------------------------------------------"
echo "# First extend the VM disk from your hypervisor/cloud console"
echo "# Then run these commands:"
echo ""

# Detect the main disk
MAIN_DISK=$(lsblk -no pkname $(findmnt -n -o SOURCE /) | head -1)
MAIN_PARTITION=$(findmnt -n -o SOURCE / | sed 's/.*\///')

echo "Detected main disk: /dev/$MAIN_DISK"
echo "Detected main partition: $MAIN_PARTITION"

echo ""
echo "# Step 1: Extend the partition"
echo "sudo growpart /dev/$MAIN_DISK $(echo $MAIN_PARTITION | grep -o '[0-9]*$')"
echo ""
echo "# Step 2: Extend the filesystem"

# Check filesystem type
FS_TYPE=$(findmnt -n -o FSTYPE /)
echo "Detected filesystem type: $FS_TYPE"

if [ "$FS_TYPE" = "ext4" ]; then
    echo "sudo resize2fs /dev/$MAIN_PARTITION"
elif [ "$FS_TYPE" = "xfs" ]; then
    echo "sudo xfs_growfs /"
else
    echo "# For $FS_TYPE filesystem:"
    echo "sudo resize2fs /dev/$MAIN_PARTITION  # Try this first"
fi

echo ""
echo "Option 3: Move K3s data to larger disk (if available)"
echo "----------------------------------------------------"
echo "# Stop K3s"
echo "sudo systemctl stop k3s"
echo ""
echo "# Create new directory on larger disk (adjust path as needed)"
echo "sudo mkdir -p /mnt/large-disk/k3s-data"
echo ""
echo "# Move existing data"
echo "sudo rsync -av /var/lib/rancher/k3s/ /mnt/large-disk/k3s-data/"
echo ""
echo "# Update K3s configuration"
echo "sudo systemctl edit k3s"
echo "# Add these lines:"
echo "# [Service]"
echo "# ExecStart="
echo "# ExecStart=/usr/local/bin/k3s server --data-dir=/mnt/large-disk/k3s-data"
echo ""
echo "# Start K3s"
echo "sudo systemctl start k3s"

echo ""
echo "==================================="
echo "🧹 IMMEDIATE CLEANUP (SAFE TO RUN)"
echo "==================================="

# Immediate cleanup commands that are safe to run
echo ""
echo "Running safe cleanup commands..."

# Clean up unused container images
echo "Cleaning unused container images..."
sudo crictl rmi --prune

# Clean up old logs (keep last 2 days)
echo "Cleaning old system logs..."
sudo journalctl --vacuum-time=2d

# Clean up package cache
echo "Cleaning package cache..."
sudo apt-get clean

# Show space freed
echo ""
echo "🎉 Cleanup complete! New disk usage:"
df -h

echo ""
echo "✅ If you need more space, run one of the extension options above."
echo "✅ Remember to extend the VM disk first if running in a virtual machine."
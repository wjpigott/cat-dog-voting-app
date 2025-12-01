#!/bin/bash
# Script to move K3s to a second disk
# Run this if you add a second disk to the VM

echo "🔍 Checking for additional disks..."
lsblk

echo ""
echo "📝 Steps to use a second disk for K3s:"
echo "1. Add a new 30GB disk to your VM"
echo "2. Run this script to set it up"
echo ""

# Check if there's a second disk
SECOND_DISK=$(lsblk -rno NAME,TYPE | grep disk | grep -v sda | head -1 | cut -d' ' -f1)

if [ -z "$SECOND_DISK" ]; then
    echo "❌ No second disk found. Please add a second disk to your VM first."
    echo ""
    echo "Instructions for adding a second disk:"
    echo "1. Shutdown your VM"
    echo "2. In your hypervisor, add a new 30GB disk"
    echo "3. Start the VM"
    echo "4. Run this script again"
    exit 1
fi

echo "✅ Found second disk: /dev/$SECOND_DISK"
echo ""
echo "🔧 Setting up the second disk for K3s..."

# Create partition
sudo fdisk /dev/$SECOND_DISK << EOF
n
p
1


w
EOF

# Format the partition
sudo mkfs.ext4 /dev/${SECOND_DISK}1

# Create mount point
sudo mkdir -p /mnt/k3s-data

# Mount the new disk
sudo mount /dev/${SECOND_DISK}1 /mnt/k3s-data

# Add to fstab for persistent mount
echo "/dev/${SECOND_DISK}1 /mnt/k3s-data ext4 defaults 0 2" | sudo tee -a /etc/fstab

echo "✅ Second disk setup complete!"
echo ""
echo "🔄 Moving K3s data to new disk..."

# Stop K3s
sudo systemctl stop k3s

# Copy existing data
sudo rsync -av /var/lib/rancher/k3s/ /mnt/k3s-data/

# Backup original directory
sudo mv /var/lib/rancher/k3s /var/lib/rancher/k3s.backup

# Create symlink to new location
sudo ln -s /mnt/k3s-data /var/lib/rancher/k3s

# Start K3s
sudo systemctl start k3s

echo "🎉 K3s data moved to second disk!"
echo "📊 New disk usage:"
df -h
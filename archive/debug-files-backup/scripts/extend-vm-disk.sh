#!/bin/bash
# Commands to run after extending the VM disk

echo "🔍 Checking current disk layout..."
lsblk

echo ""
echo "🔧 Step 1: Extending the partition..."
# Extend partition 3 (the LVM partition)
sudo growpart /dev/sda 3

echo ""
echo "🔧 Step 2: Resizing the physical volume..."
# Resize the physical volume to use the new space
sudo pvresize /dev/sda3

echo ""
echo "🔧 Step 3: Checking available space in volume group..."
sudo vgdisplay ubuntu-vg | grep "Free"

echo ""
echo "🔧 Step 4: Extending the logical volume..."
# Extend the logical volume to use all free space
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv

echo ""
echo "🔧 Step 5: Resizing the filesystem..."
# Resize the ext4 filesystem
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

echo ""
echo "🎉 Checking final disk usage..."
df -h

echo ""
echo "✅ Disk extension complete!"
# Direct Kubernetes Node Disk Extension Commands

# First, identify which nodes are out of space
Write-Host "Checking node disk usage..."

# Check disk usage on all nodes
kubectl get nodes -o wide

# Describe nodes to see disk pressure
kubectl describe nodes

# Check disk usage details
kubectl top nodes

Write-Host @"

Manual steps to extend disk on Ubuntu/Linux nodes:

1. SSH to each node that needs more disk space
2. Run these commands on each node:

# Check current disk usage
df -h

# Identify the main disk (usually /dev/sda1 or /dev/nvme0n1p1)
lsblk

# If using LVM (common setup):
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

# If using standard partitions:
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1

# For XFS filesystem:
sudo xfs_growfs /

# Verify the extension worked
df -h

3. If the underlying VM disk needs extension first:
   - Extend the VM disk size in your hypervisor (VMware, Hyper-V, etc.)
   - Then run the above filesystem extension commands

"@
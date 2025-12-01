#!/bin/bash
# Emergency K3s disk cleanup script

echo "🚨 EMERGENCY DISK CLEANUP FOR K3S"
echo "=================================="

echo "📊 Current disk usage:"
df -h /

echo ""
echo "🛑 Stopping K3s..."
sudo systemctl stop k3s

echo ""
echo "🧹 Removing all container images..."
sudo crictl rmi --all

echo ""
echo "🧹 Cleaning containerd data..."
sudo rm -rf /var/lib/containerd/io.containerd.content.v1.content/*
sudo rm -rf /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/*
sudo rm -rf /var/lib/containerd/io.containerd.metadata.v1.bolt/meta.db

echo ""
echo "🧹 Cleaning K3s cache and images..."
sudo rm -rf /var/lib/rancher/k3s/agent/images/*
sudo find /var/lib/rancher/k3s/agent/ -name "*.tar" -delete
sudo rm -rf /var/lib/rancher/k3s/server/tls/temporary-certs

echo ""
echo "🧹 Aggressive log cleanup..."
sudo journalctl --vacuum-time=6h
sudo journalctl --vacuum-size=20M

echo ""
echo "🧹 System cleanup..."
sudo apt-get clean
sudo apt-get autoremove -y --purge
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/cache/apt/archives/*

echo ""
echo "🧹 Cleaning snap cache..."
sudo rm -rf /var/lib/snapd/cache/*

echo ""
echo "🔄 Starting K3s..."
sudo systemctl start k3s

echo ""
echo "⏳ Waiting for K3s to be ready..."
sleep 30

echo ""
echo "🎉 Cleanup complete! New disk usage:"
df -h /

echo ""
echo "📊 K3s data usage after cleanup:"
sudo du -sh /var/lib/rancher/k3s/

echo ""
echo "🚀 You can now deploy your application!"
echo "kubectl get nodes"
echo "kubectl get pods"
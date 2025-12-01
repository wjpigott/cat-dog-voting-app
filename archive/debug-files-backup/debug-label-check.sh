#!/bin/bash
# Run this script on your Linux on-premises machine (66.242.207.21)

echo "🔍 Checking label mismatch issue..."
echo "========================================="

echo "📋 Pod labels:"
kubectl get pod voting-app-enhanced-debug-5b7546f74d-rjszn --show-labels

echo ""
echo "📋 Service selector:"
kubectl get service voting-app-debug-service -o yaml | grep -A 5 selector

echo ""
echo "🧪 Direct pod IP test:"
POD_IP=$(kubectl get pod voting-app-enhanced-debug-5b7546f74d-rjszn -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"
curl -m 10 http://$POD_IP:5000/health

echo ""
echo "🌐 Service test:"
curl -m 10 http://66.242.207.21:31517/health

echo ""
echo "🔧 If still failing, try port forwarding test:"
echo "kubectl port-forward pod/voting-app-enhanced-debug-5b7546f74d-rjszn 8080:5000 &"
echo "sleep 5"
echo "curl http://localhost:8080/health"
echo "pkill -f 'kubectl port-forward'"

echo ""
echo "📝 Check pod logs:"
kubectl logs voting-app-enhanced-debug-5b7546f74d-rjszn --tail=10
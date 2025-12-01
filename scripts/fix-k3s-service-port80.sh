# Quick Fix: Update K3s Service to Use Port 80
# This makes the voting app accessible on standard HTTP port

# SSH to your K3s machine and run:

# Option A: Update existing service to use port 80
kubectl patch service azure-vote-front --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30080}]'

# Option B: Create a new LoadBalancer service on port 80
kubectl expose deployment azure-vote-front --name=voting-app-port80 --type=LoadBalancer --port=80 --target-port=80

# Option C: If your voting app container runs on different port, forward it
kubectl port-forward deployment/azure-vote-front 80:8080 --address=0.0.0.0

# Then test:
curl http://66.242.207.21:80

# After this works, Traffic Manager will route correctly to:
# http://voting-app-tm-2334-cstgesqvnzeko.trafficmanager.net
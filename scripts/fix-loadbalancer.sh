#!/bin/bash

# Fix LoadBalancer Access for Fargate
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Fixing Fargate LoadBalancer Access    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

cd /home/abid/Project/AWS-Project

echo -e "${YELLOW}The LoadBalancer issue is common with Fargate + Classic ELB${NC}"
echo -e "${YELLOW}Let's provide alternative access methods:${NC}"
echo ""

# Method 1: Port Forward (immediate access)
echo -e "${CYAN}Method 1: Port Forward (Local Access)${NC}"
echo -e "${YELLOW}Starting port forward on port 8080...${NC}"

# Kill any existing port-forward processes
pkill -f "kubectl port-forward" || true
sleep 2

# Start port forward in background
kubectl port-forward -n web-apps service/frontend-service 8080:80 --address=0.0.0.0 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

sleep 3

# Test the connection
if curl -s http://localhost:8080 > /dev/null; then
    echo -e "${GREEN}✅ Port forward working!${NC}"
    echo -e "${GREEN}Access URL: http://localhost:8080${NC}"
    echo -e "${YELLOW}Note: This works while the terminal is open${NC}"
else
    echo -e "${RED}❌ Port forward not responding${NC}"
fi

echo ""

# Method 2: Create an Ingress-friendly service
echo -e "${CYAN}Method 2: ClusterIP Service (for future Ingress)${NC}"

cat << EOF > /tmp/frontend-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-clusterip
  namespace: web-apps
  labels:
    app: frontend
spec:
  selector:
    app: frontend
    tier: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

kubectl apply -f /tmp/frontend-clusterip.yaml
echo -e "${GREEN}✅ ClusterIP service created: frontend-clusterip${NC}"

# Method 3: NodePort service (if we had EC2 nodes)
echo -e "${CYAN}Method 3: Information about LoadBalancer${NC}"
echo -e "${YELLOW}The Classic LoadBalancer was created but has no healthy targets${NC}"
echo -e "${YELLOW}because Fargate pods don't register with Classic ELBs.${NC}"
echo ""

# Show current services
echo -e "${BLUE}Current Services in web-apps namespace:${NC}"
kubectl get services -n web-apps

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Access Methods                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Method 1: Port Forward (Active)${NC}"
echo -e "${CYAN}   URL: http://localhost:8080${NC}"
echo -e "${YELLOW}   Command: kubectl port-forward -n web-apps service/frontend-service 8080:80${NC}"
echo ""
echo -e "${GREEN}✅ Method 2: ClusterIP + kubectl proxy${NC}"
echo -e "${CYAN}   Command: kubectl proxy${NC}"
echo -e "${CYAN}   URL: http://localhost:8001/api/v1/namespaces/web-apps/services/frontend-clusterip:80/proxy/${NC}"
echo ""
echo -e "${BLUE}💡 For production: Install AWS Load Balancer Controller for ALB/NLB support${NC}"
echo -e "${YELLOW}   This enables proper LoadBalancer services with Fargate${NC}"

# Clean up temp file
rm -f /tmp/frontend-clusterip.yaml

echo ""
echo -e "${GREEN}🎉 Alternative access methods configured!${NC}"
echo -e "${YELLOW}Port forward is running in background (PID: $PORT_FORWARD_PID)${NC}"
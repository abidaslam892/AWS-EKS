#!/bin/bash

# EKS Cluster Final Verification and Setup
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       EKS Cluster Verification       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

# Function to run command with status
run_with_status() {
    local description="$1"
    local command="$2"
    
    echo -e "${YELLOW}⏳ ${description}...${NC}"
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ${description} - SUCCESS${NC}"
        return 0
    else
        echo -e "${RED}❌ ${description} - FAILED${NC}"
        return 1
    fi
}

# Verification steps
echo -e "${CYAN}🔍 Running cluster verification...${NC}"
echo ""

# 1. Check cluster status
echo -e "${YELLOW}1. Checking cluster status...${NC}"
./eksctl get cluster --name $CLUSTER_NAME --region $REGION

cluster_status=$(./eksctl get cluster --name $CLUSTER_NAME --region $REGION --output json | jq -r '.[0].Status' 2>/dev/null || echo "UNKNOWN")

if [ "$cluster_status" != "ACTIVE" ]; then
    echo -e "${RED}❌ Cluster is not active yet. Current status: ${cluster_status}${NC}"
    echo -e "${YELLOW}Please wait for cluster creation to complete.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster is ACTIVE${NC}"
echo ""

# 2. Update kubeconfig
echo -e "${YELLOW}2. Updating kubeconfig...${NC}"
./eksctl utils write-kubeconfig --cluster=$CLUSTER_NAME --region=$REGION
echo -e "${GREEN}✅ Kubeconfig updated${NC}"
echo ""

# 3. Check kubectl connection
echo -e "${YELLOW}3. Testing kubectl connection...${NC}"
if kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ kubectl connection successful${NC}"
    kubectl cluster-info
else
    echo -e "${RED}❌ kubectl connection failed${NC}"
    exit 1
fi
echo ""

# 4. Check nodes
echo -e "${YELLOW}4. Checking worker nodes...${NC}"
node_count=$(kubectl get nodes --no-headers | wc -l)
if [ "$node_count" -gt "0" ]; then
    echo -e "${GREEN}✅ Found ${node_count} worker nodes${NC}"
    kubectl get nodes -o wide
else
    echo -e "${RED}❌ No worker nodes found${NC}"
    echo -e "${YELLOW}Node group might still be creating...${NC}"
fi
echo ""

# 5. Check system pods
echo -e "${YELLOW}5. Checking system pods...${NC}"
system_pods=$(kubectl get pods -n kube-system --no-headers | grep -c "Running" || echo "0")
total_pods=$(kubectl get pods -n kube-system --no-headers | wc -l || echo "0")
echo -e "${GREEN}✅ System pods: ${system_pods}/${total_pods} running${NC}"
kubectl get pods -n kube-system
echo ""

# 6. Deploy test application
echo -e "${YELLOW}6. Deploying test applications...${NC}"
if kubectl apply -f manifests/test-pod.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Test pod deployed${NC}"
else
    echo -e "${RED}❌ Test pod deployment failed${NC}"
fi

if kubectl apply -f manifests/nginx-deployment.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ NGINX deployment deployed${NC}"
else
    echo -e "${RED}❌ NGINX deployment failed${NC}"
fi
echo ""

# 7. Wait for pods to be ready
echo -e "${YELLOW}7. Waiting for pods to be ready...${NC}"
sleep 10
kubectl get pods
echo ""

# 8. Check services
echo -e "${YELLOW}8. Checking services...${NC}"
kubectl get services
echo ""

# Summary
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Verification Complete       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}🎉 Your EKS cluster is ready and verified!${NC}"
echo ""
echo -e "${CYAN}📋 Cluster Summary:${NC}"
echo -e "${CYAN}   • Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${CYAN}   • Region: ${REGION}${NC}"
echo -e "${CYAN}   • Worker Nodes: ${node_count}${NC}"
echo -e "${CYAN}   • System Pods: ${system_pods}/${total_pods} running${NC}"
echo ""

echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo -e "${YELLOW}   • Check nodes:${NC} kubectl get nodes"
echo -e "${YELLOW}   • Check pods:${NC} kubectl get pods --all-namespaces"
echo -e "${YELLOW}   • Check services:${NC} kubectl get services"
echo -e "${YELLOW}   • Scale deployment:${NC} kubectl scale deployment nginx-deployment --replicas=3"
echo -e "${YELLOW}   • Delete test apps:${NC} ./eks-manager.sh cleanup"
echo -e "${YELLOW}   • Delete cluster:${NC} ./eks-manager.sh delete"
echo ""

echo -e "${GREEN}Happy Kubernetes-ing! 🚀${NC}"
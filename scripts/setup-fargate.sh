#!/bin/bash

# EKS Fargate Profile Setup Script
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
echo -e "${BLUE}║      EKS Fargate Profile Setup       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

# Function to create fargate profile with error handling
create_fargate_profile() {
    local profile_name="$1"
    local namespace="$2"
    local labels="$3"
    
    echo -e "${YELLOW}Creating Fargate profile: ${profile_name}${NC}"
    
    if [ -n "$labels" ]; then
        ./eksctl create fargateprofile \
            --cluster=$CLUSTER_NAME \
            --region=$REGION \
            --name=$profile_name \
            --namespace=$namespace \
            --labels="$labels"
    else
        ./eksctl create fargateprofile \
            --cluster=$CLUSTER_NAME \
            --region=$REGION \
            --name=$profile_name \
            --namespace=$namespace
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Fargate profile ${profile_name} created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create Fargate profile ${profile_name}${NC}"
        return 1
    fi
}

# Check cluster status
echo -e "${CYAN}🔍 Checking cluster status...${NC}"
cluster_status=$(./eksctl get cluster --name $CLUSTER_NAME --region $REGION --output json | jq -r '.[0].Status' 2>/dev/null || echo "UNKNOWN")

if [ "$cluster_status" != "ACTIVE" ]; then
    echo -e "${RED}❌ Cluster is not active. Current status: ${cluster_status}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster is ACTIVE${NC}"
echo ""

# Create namespaces for Fargate
echo -e "${CYAN}📁 Creating namespaces for Fargate workloads...${NC}"

kubectl create namespace fargate-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace applications --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace web-apps --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Namespaces created${NC}"
echo ""

# Create Fargate profiles
echo -e "${CYAN}🚀 Creating Fargate profiles...${NC}"
echo ""

# Profile 1: Default namespace with fargate label
create_fargate_profile "default-fargate" "default" "compute-type=fargate"

# Profile 2: Dedicated fargate namespace
create_fargate_profile "fargate-namespace" "fargate-ns" ""

# Profile 3: Application namespace with fargate label
create_fargate_profile "app-fargate" "applications" "compute-type=fargate"

# Profile 4: Web apps with frontend tier
create_fargate_profile "frontend-fargate" "web-apps" "tier=frontend"

echo ""
echo -e "${CYAN}📋 Listing all Fargate profiles...${NC}"
./eksctl get fargateprofile --cluster $CLUSTER_NAME --region $REGION

echo ""
echo -e "${GREEN}🎉 Fargate profiles setup completed!${NC}"
echo ""
echo -e "${BLUE}💡 How to use Fargate:${NC}"
echo ""
echo -e "${YELLOW}1. Deploy to default namespace with Fargate:${NC}"
echo "   kubectl apply -f manifests/fargate-test-pod.yaml"
echo ""
echo -e "${YELLOW}2. Deploy to fargate-ns namespace:${NC}"
echo "   kubectl apply -f manifests/fargate-app.yaml"
echo ""
echo -e "${YELLOW}3. Check Fargate pods:${NC}"
echo "   kubectl get pods -n fargate-ns -o wide"
echo "   kubectl get pods -n default -l compute-type=fargate -o wide"
echo ""
echo -e "${BLUE}📝 Note:${NC} Pods will be scheduled on Fargate when they match the namespace and label selectors."
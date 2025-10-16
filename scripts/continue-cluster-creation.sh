#!/bin/bash

# EKS Cluster Creation Continuation Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

echo -e "${BLUE}=== EKS Cluster Creation Continuation ===${NC}"
echo -e "${BLUE}Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

# Function to wait for CloudFormation stack completion
wait_for_stack() {
    local stack_name=$1
    local timeout=1800  # 30 minutes timeout
    local elapsed=0
    local interval=30   # Check every 30 seconds
    
    echo -e "${YELLOW}Waiting for CloudFormation stack ${stack_name} to complete...${NC}"
    
    while [ $elapsed -lt $timeout ]; do
        local status=$(aws cloudformation describe-stacks \
            --region $REGION \
            --stack-name $stack_name \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null || echo "STACK_NOT_FOUND")
        
        case $status in
            "CREATE_COMPLETE")
                echo -e "${GREEN}✅ Stack ${stack_name} created successfully!${NC}"
                return 0
                ;;
            "CREATE_FAILED"|"ROLLBACK_COMPLETE"|"ROLLBACK_FAILED")
                echo -e "${RED}❌ Stack ${stack_name} creation failed with status: ${status}${NC}"
                return 1
                ;;
            "CREATE_IN_PROGRESS"|"REVIEW_IN_PROGRESS")
                printf "."
                ;;
            "STACK_NOT_FOUND")
                echo -e "${RED}❌ Stack ${stack_name} not found${NC}"
                return 1
                ;;
            *)
                echo -e "${YELLOW}⏳ Stack status: ${status}${NC}"
                ;;
        esac
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo -e "${RED}❌ Timeout waiting for stack ${stack_name}${NC}"
    return 1
}

# Check current cluster status
echo -e "${YELLOW}Checking current cluster status...${NC}"
./eksctl get cluster --name $CLUSTER_NAME --region $REGION || true

# Wait for control plane stack to complete
if ! wait_for_stack "eksctl-my-eks-cluster-cluster"; then
    echo -e "${RED}Control plane creation failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Control plane ready! Now creating managed node group...${NC}"

# Create managed node group
./eksctl create nodegroup \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --name=worker-nodes \
    --node-type=t3.medium \
    --nodes=2 \
    --nodes-min=1 \
    --nodes-max=4 \
    --managed

# Update kubeconfig
echo -e "${YELLOW}Updating kubeconfig...${NC}"
./eksctl utils write-kubeconfig --cluster=$CLUSTER_NAME --region=$REGION

# Verify cluster is ready
echo -e "${YELLOW}Verifying cluster is ready...${NC}"
kubectl get nodes

echo -e "${GREEN}🎉 EKS cluster is fully ready!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Deploy test applications: ./eks-manager.sh test"
echo "2. Check cluster status: ./eks-manager.sh status"
echo "3. View all pods: ./eks-manager.sh pods"
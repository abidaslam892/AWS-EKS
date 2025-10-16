#!/bin/bash

# EKS Cluster Creation Monitor
set -e

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== EKS Cluster Creation Monitor ===${NC}"
echo -e "${BLUE}Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

check_cluster_status() {
    echo -e "${YELLOW}Checking cluster status...${NC}"
    
    # Check if cluster exists and get status
    if ./eksctl get cluster --name $CLUSTER_NAME --region $REGION >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Cluster found! Getting details...${NC}"
        ./eksctl get cluster --name $CLUSTER_NAME --region $REGION
        
        # Try to get nodes
        echo -e "${YELLOW}Checking worker nodes...${NC}"
        if kubectl get nodes >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Worker nodes are ready!${NC}"
            kubectl get nodes
            return 0
        else
            echo -e "${YELLOW}⏳ Worker nodes not ready yet...${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⏳ Cluster still being created...${NC}"
        return 1
    fi
}

# Check AWS CloudFormation stacks
check_cloudformation() {
    echo -e "${YELLOW}Checking CloudFormation stacks...${NC}"
    aws cloudformation describe-stacks \
        --region $REGION \
        --query 'Stacks[?contains(StackName, `eksctl-my-eks-cluster`)].{Name:StackName,Status:StackStatus}' \
        --output table
}

echo -e "${BLUE}Current Status:${NC}"
check_cloudformation
echo ""

if check_cluster_status; then
    echo ""
    echo -e "${GREEN}🎉 EKS Cluster is ready!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Deploy test applications: ./eks-manager.sh test"
    echo "2. Check cluster status: ./eks-manager.sh status"
    echo "3. View all pods: ./eks-manager.sh pods"
else
    echo ""
    echo -e "${YELLOW}⏳ Cluster is still being created. Please wait...${NC}"
    echo -e "${BLUE}You can monitor progress in the AWS Console:${NC}"
    echo "https://console.aws.amazon.com/eks/home?region=${REGION}#/clusters"
    echo ""
    echo -e "${BLUE}Or check CloudFormation stacks:${NC}"
    echo "https://console.aws.amazon.com/cloudformation/home?region=${REGION}"
fi
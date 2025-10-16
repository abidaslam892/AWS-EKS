#!/bin/bash

# Simple EKS Cluster Creation Script
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

echo -e "${BLUE}=== Creating Simple EKS Cluster ===${NC}"
echo -e "${BLUE}Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
aws sts get-caller-identity

echo -e "${YELLOW}Creating EKS cluster (this will take 10-15 minutes)...${NC}"

# Create a simple cluster first
./eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name worker-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

echo -e "${GREEN}✅ EKS cluster created successfully!${NC}"

# Update kubeconfig
echo -e "${YELLOW}Updating kubeconfig...${NC}"
./eksctl utils write-kubeconfig --cluster=$CLUSTER_NAME --region=$REGION

# Verify cluster access
echo -e "${YELLOW}Verifying cluster access...${NC}"
kubectl get nodes

echo -e "${GREEN}🎉 Your EKS cluster is ready!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. kubectl get nodes - to see your worker nodes"
echo "2. kubectl get pods --all-namespaces - to see system pods"
echo "3. Deploy your applications!"
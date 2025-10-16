#!/bin/bash

# EKS Cluster Setup Script
# This script creates an EKS cluster with all necessary configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"
CONFIG_FILE="./eks-setup/cluster-config.yaml"

echo -e "${BLUE}=== EKS Cluster Setup Script ===${NC}"
echo -e "${BLUE}Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists aws; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

if [ ! -f "./eksctl" ]; then
    echo -e "${RED}eksctl is not found in current directory. Please ensure it's available.${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}AWS credentials are not configured properly.${NC}"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account: ${AWS_ACCOUNT}${NC}"

# Check if cluster already exists
echo -e "${YELLOW}Checking if cluster already exists...${NC}"
if ./eksctl get cluster --name $CLUSTER_NAME --region $REGION > /dev/null 2>&1; then
    echo -e "${YELLOW}Cluster ${CLUSTER_NAME} already exists. Skipping creation...${NC}"
    echo -e "${BLUE}Updating kubeconfig...${NC}"
    ./eksctl utils write-kubeconfig --cluster=$CLUSTER_NAME --region=$REGION
else
    # Create the cluster
    echo -e "${GREEN}Creating EKS cluster...${NC}"
    echo -e "${YELLOW}This will take approximately 10-15 minutes...${NC}"
    
    ./eksctl create cluster -f $CONFIG_FILE
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ EKS cluster created successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to create EKS cluster${NC}"
        exit 1
    fi
fi

# Verify cluster access
echo -e "${YELLOW}Verifying cluster access...${NC}"
kubectl get nodes

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully connected to the cluster!${NC}"
else
    echo -e "${RED}❌ Failed to connect to the cluster${NC}"
    exit 1
fi

# Install additional components
echo -e "${YELLOW}Installing additional components...${NC}"

# Install AWS Load Balancer Controller
echo -e "${BLUE}Installing AWS Load Balancer Controller...${NC}"
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Install metrics-server
echo -e "${BLUE}Installing metrics-server...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install cluster-autoscaler
echo -e "${BLUE}Installing cluster-autoscaler...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Patch cluster-autoscaler deployment
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'

kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"cluster-autoscaler","command":["./cluster-autoscaler","--v=4","--stderrthreshold=info","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/'$CLUSTER_NAME'"]}]}}}}'

echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}=== Cluster Information ===${NC}"
echo -e "${GREEN}Cluster Name: ${CLUSTER_NAME}${NC}"
echo -e "${GREEN}Region: ${REGION}${NC}"
echo -e "${GREEN}Account: ${AWS_ACCOUNT}${NC}"
echo ""
echo -e "${BLUE}=== Useful Commands ===${NC}"
echo -e "${YELLOW}Get cluster info:${NC} kubectl cluster-info"
echo -e "${YELLOW}Get nodes:${NC} kubectl get nodes"
echo -e "${YELLOW}Get pods:${NC} kubectl get pods --all-namespaces"
echo -e "${YELLOW}Get services:${NC} kubectl get services --all-namespaces"
echo ""
echo -e "${GREEN}🎉 Your EKS cluster is ready to use!${NC}"
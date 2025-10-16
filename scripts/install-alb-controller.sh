#!/bin/bash

# AWS Load Balancer Controller Installation Script
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
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AWS Load Balancer Controller Setup       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

echo -e "${CYAN}🔍 Installing AWS Load Balancer Controller...${NC}"
echo -e "${YELLOW}Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${YELLOW}Cluster: ${CLUSTER_NAME}${NC}"
echo -e "${YELLOW}Region: ${REGION}${NC}"
echo ""

# Step 1: Create IAM service account for AWS Load Balancer Controller
echo -e "${YELLOW}1. Creating IAM service account...${NC}"
./eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --region=$REGION \
  --approve

echo -e "${GREEN}✅ IAM service account created${NC}"

# Step 2: Install cert-manager (required by ALB controller)
echo -e "${YELLOW}2. Installing cert-manager...${NC}"
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
echo -e "${YELLOW}Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

echo -e "${GREEN}✅ cert-manager installed${NC}"

# Step 3: Download AWS Load Balancer Controller YAML
echo -e "${YELLOW}3. Downloading AWS Load Balancer Controller manifest...${NC}"
curl -Lo v2_6_2_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.6.2/v2_6_2_full.yaml

# Step 4: Modify the manifest
echo -e "${YELLOW}4. Configuring AWS Load Balancer Controller...${NC}"

# Replace cluster name in the manifest
sed -i "s/your-cluster-name/$CLUSTER_NAME/g" v2_6_2_full.yaml

# Remove ServiceAccount section (we created it with eksctl)
sed -i '/^apiVersion: v1$/,/^---$/{ /kind: ServiceAccount/,/^---$/d; }' v2_6_2_full.yaml

# Step 5: Apply the manifest
echo -e "${YELLOW}5. Installing AWS Load Balancer Controller...${NC}"
kubectl apply -f v2_6_2_full.yaml

echo -e "${YELLOW}Waiting for AWS Load Balancer Controller to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Step 6: Verify installation
echo -e "${YELLOW}6. Verifying installation...${NC}"
kubectl get deployment -n kube-system aws-load-balancer-controller

echo -e "${GREEN}✅ AWS Load Balancer Controller installed successfully!${NC}"

# Clean up
rm -f v2_6_2_full.yaml

echo ""
echo -e "${CYAN}🔄 Now updating LoadBalancer services...${NC}"

# Delete and recreate the LoadBalancer service to trigger proper provisioning
kubectl delete service frontend-service -n web-apps
sleep 5
kubectl apply -f manifests/frontend-fargate.yaml

echo -e "${GREEN}✅ LoadBalancer service recreated${NC}"
echo ""
echo -e "${BLUE}💡 Wait 2-3 minutes and check:${NC}"
echo "kubectl get service frontend-service -n web-apps"
echo ""
echo -e "${YELLOW}The LoadBalancer should now work properly with Fargate!${NC}"
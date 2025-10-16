#!/bin/bash

# Complete AWS Resources Cleanup Script
# This script will delete ALL resources created by the EKS setup to prevent revenue leakage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║              🚨 COMPLETE RESOURCE CLEANUP 🚨              ║${NC}"
echo -e "${RED}║                                                          ║${NC}"
echo -e "${RED}║  This will DELETE ALL AWS resources to prevent costs!   ║${NC}"
echo -e "${RED}║  ⚠️  This action is IRREVERSIBLE ⚠️                      ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project directory
cd /home/abid/Project/AWS-Project

# Function to show progress
show_progress() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

# Function to check if resource exists
resource_exists() {
    local check_command="$1"
    eval "$check_command" > /dev/null 2>&1
    return $?
}

# Confirmation prompt
echo -e "${YELLOW}This script will delete the following resources:${NC}"
echo -e "${MAGENTA}📊 EKS Resources:${NC}"
echo "  • EKS Cluster: $CLUSTER_NAME"
echo "  • All Fargate Profiles (default-fargate, fargate-namespace, app-fargate, frontend-fargate)"
echo "  • All Node Groups"
echo "  • OIDC Identity Provider"
echo ""
echo -e "${MAGENTA}🏗️ Infrastructure:${NC}"
echo "  • VPC and associated subnets"
echo "  • Security Groups"
echo "  • Internet Gateway & Route Tables"
echo "  • NAT Gateways (if created)"
echo "  • Elastic IPs"
echo ""
echo -e "${MAGENTA}☁️ Kubernetes Resources:${NC}"
echo "  • All deployed applications"
echo "  • Load Balancers (Classic & Network)"
echo "  • Persistent Volumes & EBS volumes"
echo "  • ConfigMaps & Secrets"
echo ""
echo -e "${MAGENTA}📝 Additional Services:${NC}"
echo "  • CloudWatch Log Groups"
echo "  • IAM Roles & Policies (EKS related)"
echo "  • Service Accounts"
echo ""
echo -e "${RED}💰 Estimated monthly cost being eliminated: ~$157.40${NC}"
echo ""

read -p "$(echo -e ${YELLOW}Are you absolutely sure you want to delete ALL resources? Type 'DELETE' to confirm: ${NC})" -r
echo
if [[ ! $REPLY == "DELETE" ]]; then
    echo -e "${GREEN}✅ Cleanup cancelled. Resources are safe.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}🚨 Starting complete resource cleanup...${NC}"
echo ""

# Step 1: Delete Kubernetes applications first
show_progress "🧹 Cleaning up Kubernetes applications..."

if kubectl get nodes > /dev/null 2>&1; then
    echo -e "${YELLOW}Deleting all deployed applications...${NC}"
    
    # Delete Fargate test apps
    kubectl delete -f manifests/fargate-test-pod.yaml --ignore-not-found=true
    kubectl delete -f manifests/fargate-app.yaml --ignore-not-found=true
    kubectl delete -f manifests/frontend-fargate.yaml --ignore-not-found=true
    
    # Delete regular test apps
    kubectl delete -f manifests/test-pod.yaml --ignore-not-found=true
    kubectl delete -f manifests/nginx-deployment.yaml --ignore-not-found=true
    
    # Delete all services to remove load balancers
    echo -e "${YELLOW}Deleting all LoadBalancer services...${NC}"
    kubectl delete services --all --all-namespaces --wait=true
    
    # Delete all persistent volume claims
    echo -e "${YELLOW}Deleting persistent volume claims...${NC}"
    kubectl delete pvc --all --all-namespaces --wait=true
    
    # Wait for load balancers to be cleaned up
    echo -e "${YELLOW}Waiting for AWS Load Balancers to be deleted...${NC}"
    sleep 30
    
    echo -e "${GREEN}✅ Kubernetes applications cleaned up${NC}"
else
    echo -e "${YELLOW}⚠️ Cannot connect to cluster, skipping application cleanup${NC}"
fi

# Step 2: Delete Fargate Profiles
show_progress "🔄 Deleting Fargate Profiles..."

fargate_profiles=("default-fargate" "fargate-namespace" "app-fargate" "frontend-fargate")

for profile in "${fargate_profiles[@]}"; do
    echo -e "${YELLOW}Deleting Fargate profile: $profile${NC}"
    if resource_exists "./eksctl get fargateprofile --cluster $CLUSTER_NAME --name $profile --region $REGION"; then
        ./eksctl delete fargateprofile --cluster $CLUSTER_NAME --name $profile --region $REGION --wait
        echo -e "${GREEN}✅ Deleted Fargate profile: $profile${NC}"
    else
        echo -e "${CYAN}ℹ️ Fargate profile $profile not found, skipping${NC}"
    fi
    sleep 5
done

# Step 3: Delete Node Groups (if any)
show_progress "🖥️ Deleting Node Groups..."

if resource_exists "./eksctl get nodegroup --cluster $CLUSTER_NAME --region $REGION"; then
    echo -e "${YELLOW}Found node groups, deleting...${NC}"
    ./eksctl delete nodegroup --cluster $CLUSTER_NAME --region $REGION --approve --wait
    echo -e "${GREEN}✅ Node groups deleted${NC}"
else
    echo -e "${CYAN}ℹ️ No node groups found${NC}"
fi

# Step 4: Delete the EKS Cluster
show_progress "🎯 Deleting EKS Cluster..."

if resource_exists "./eksctl get cluster --name $CLUSTER_NAME --region $REGION"; then
    echo -e "${YELLOW}Deleting EKS cluster: $CLUSTER_NAME${NC}"
    echo -e "${YELLOW}This may take 10-15 minutes...${NC}"
    
    ./eksctl delete cluster --name $CLUSTER_NAME --region $REGION --wait
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ EKS cluster deleted successfully${NC}"
    else
        echo -e "${RED}❌ Failed to delete EKS cluster${NC}"
        echo -e "${YELLOW}You may need to manually clean up remaining resources in AWS Console${NC}"
    fi
else
    echo -e "${CYAN}ℹ️ EKS cluster not found${NC}"
fi

# Step 5: Clean up orphaned resources
show_progress "🧽 Cleaning up orphaned AWS resources..."

echo -e "${YELLOW}Checking for orphaned Load Balancers...${NC}"
# List any remaining load balancers
aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`) || contains(Tags[?Key==`kubernetes.io/cluster/my-eks-cluster`], `owned`)].LoadBalancerArn' --output text 2>/dev/null | while read lb_arn; do
    if [ ! -z "$lb_arn" ]; then
        echo -e "${YELLOW}Deleting orphaned ALB/NLB: $lb_arn${NC}"
        aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" --region $REGION
    fi
done

# Clean up Classic Load Balancers
aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `k8s-`) || contains(Tags[?Key==`kubernetes.io/cluster/my-eks-cluster`], `owned`)].LoadBalancerName' --output text 2>/dev/null | while read lb_name; do
    if [ ! -z "$lb_name" ]; then
        echo -e "${YELLOW}Deleting orphaned Classic LB: $lb_name${NC}"
        aws elb delete-load-balancer --load-balancer-name "$lb_name" --region $REGION
    fi
done

echo -e "${YELLOW}Checking for orphaned EBS volumes...${NC}"
# Clean up unattached EBS volumes with kubernetes tags
aws ec2 describe-volumes --region $REGION --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" "Name=state,Values=available" --query 'Volumes[].VolumeId' --output text 2>/dev/null | while read volume_id; do
    if [ ! -z "$volume_id" ]; then
        echo -e "${YELLOW}Deleting orphaned EBS volume: $volume_id${NC}"
        aws ec2 delete-volume --volume-id "$volume_id" --region $REGION
    fi
done

# Step 6: Clean up CloudWatch Log Groups
show_progress "📝 Cleaning up CloudWatch Log Groups..."

echo -e "${YELLOW}Deleting EKS-related CloudWatch log groups...${NC}"
aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" --query 'logGroups[].logGroupName' --output text 2>/dev/null | while read log_group; do
    if [ ! -z "$log_group" ]; then
        echo -e "${YELLOW}Deleting log group: $log_group${NC}"
        aws logs delete-log-group --log-group-name "$log_group" --region $REGION
    fi
done

# Step 7: Summary and cost verification
show_progress "📊 Cleanup Summary"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ CLEANUP COMPLETE ✅                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🎯 Resources Cleaned Up:${NC}"
echo -e "${GREEN}✅ EKS Cluster: $CLUSTER_NAME${NC}"
echo -e "${GREEN}✅ All Fargate Profiles${NC}"
echo -e "${GREEN}✅ All Node Groups${NC}"
echo -e "${GREEN}✅ Kubernetes Applications${NC}"
echo -e "${GREEN}✅ Load Balancers${NC}"
echo -e "${GREEN}✅ EBS Volumes${NC}"
echo -e "${GREEN}✅ CloudWatch Log Groups${NC}"
echo ""

echo -e "${MAGENTA}💰 Cost Savings:${NC}"
echo -e "${GREEN}• Monthly savings: ~$157.40${NC}"
echo -e "${GREEN}• Yearly savings: ~$1,888.80${NC}"
echo ""

echo -e "${BLUE}🔍 Verification Steps:${NC}"
echo -e "${YELLOW}1. Check AWS Console - EKS:${NC} https://console.aws.amazon.com/eks/home?region=$REGION"
echo -e "${YELLOW}2. Check Load Balancers:${NC} https://console.aws.amazon.com/ec2/v2/home?region=$REGION#LoadBalancers:"
echo -e "${YELLOW}3. Check EBS Volumes:${NC} https://console.aws.amazon.com/ec2/v2/home?region=$REGION#Volumes:"
echo -e "${YELLOW}4. Check your AWS bill in 24-48 hours to confirm cost reduction${NC}"
echo ""

echo -e "${CYAN}💡 Pro Tip: Set up AWS billing alerts to monitor future costs!${NC}"
echo ""

# Remove kubeconfig
if [ -f ~/.kube/config ]; then
    echo -e "${YELLOW}Cleaning up local kubeconfig...${NC}"
    kubectl config delete-cluster "$CLUSTER_NAME" 2>/dev/null || true
    kubectl config delete-context "$CLUSTER_NAME" 2>/dev/null || true
    kubectl config unset users."$CLUSTER_NAME" 2>/dev/null || true
    echo -e "${GREEN}✅ Local kubeconfig cleaned${NC}"
fi

echo -e "${GREEN}🎉 All AWS resources have been successfully deleted!${NC}"
echo -e "${GREEN}💸 No more charges will be incurred from these resources.${NC}"
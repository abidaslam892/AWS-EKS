#!/bin/bash

# AWS Cost Monitoring Script for EKS Resources
# This script helps monitor AWS costs to prevent revenue leakage

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

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    💰 COST MONITOR 💰                     ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║         AWS EKS Resource Cost Tracking & Alerts         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to show progress
show_progress() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

# Check AWS CLI and credentials
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account: ${AWS_ACCOUNT}${NC}"
echo -e "${GREEN}Region: ${REGION}${NC}"
echo ""

# Function to check running resources
check_running_resources() {
    show_progress "🔍 Scanning for active EKS resources..."
    
    local total_cost=0
    local resources_found=false
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                     ACTIVE RESOURCES                      ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check EKS Cluster
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
        echo -e "${RED}🎛️  EKS Control Plane: $CLUSTER_NAME${NC}"
        echo -e "   💰 Cost: $72.00/month ($0.10/hour)"
        total_cost=$(echo "$total_cost + 72.00" | bc)
        resources_found=true
    fi
    
    # Check Fargate Profiles
    fargate_profiles=$(aws eks list-fargate-profiles --cluster-name "$CLUSTER_NAME" --region "$REGION" --query 'fargateProfileNames' --output text 2>/dev/null || echo "")
    if [ ! -z "$fargate_profiles" ] && [ "$fargate_profiles" != "None" ]; then
        profile_count=$(echo $fargate_profiles | wc -w)
        echo -e "${RED}☁️  Fargate Profiles: $profile_count active${NC}"
        echo -e "   📋 Profiles: $fargate_profiles"
        
        # Estimate Fargate costs based on running pods
        fargate_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running -o json 2>/dev/null | jq -r '.items[] | select(.spec.nodeName | test("fargate")) | .metadata.name' 2>/dev/null | wc -l || echo "0")
        if [ "$fargate_pods" -gt 0 ]; then
            fargate_cost=$(echo "$fargate_pods * 7.20" | bc) # $7.20 per pod (0.25 vCPU, 0.5GB)
            echo -e "   💰 Estimated Cost: \$${fargate_cost}/month (${fargate_pods} pods)"
            total_cost=$(echo "$total_cost + $fargate_cost" | bc)
        fi
        resources_found=true
    fi
    
    # Check Load Balancers
    elb_count=$(aws elb describe-load-balancers --region "$REGION" --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `k8s-`)].LoadBalancerName' --output text 2>/dev/null | wc -w || echo "0")
    if [ "$elb_count" -gt 0 ]; then
        echo -e "${RED}⚖️  Classic Load Balancers: $elb_count active${NC}"
        lb_cost=$(echo "$elb_count * 18.00" | bc)
        echo -e "   💰 Cost: \$${lb_cost}/month (\$18.00 each)"
        total_cost=$(echo "$total_cost + $lb_cost" | bc)
        resources_found=true
    fi
    
    alb_count=$(aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`)].LoadBalancerArn' --output text 2>/dev/null | wc -w || echo "0")
    if [ "$alb_count" -gt 0 ]; then
        echo -e "${RED}🌐 Application/Network Load Balancers: $alb_count active${NC}"
        alb_cost=$(echo "$alb_count * 22.50" | bc) # ALB/NLB cost more
        echo -e "   💰 Cost: \$${alb_cost}/month (\$22.50 each)"
        total_cost=$(echo "$total_cost + $alb_cost" | bc)
        resources_found=true
    fi
    
    # Check EBS Volumes
    ebs_volumes=$(aws ec2 describe-volumes --region "$REGION" --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" --query 'Volumes[?State==`in-use` || State==`available`].[VolumeId,Size,VolumeType]' --output text 2>/dev/null || echo "")
    if [ ! -z "$ebs_volumes" ]; then
        ebs_cost=0
        volume_count=0
        while IFS=$'\t' read -r volume_id size volume_type; do
            if [ ! -z "$volume_id" ]; then
                volume_count=$((volume_count + 1))
                # Calculate cost based on volume type (gp2: $0.10/GB/month)
                vol_cost=$(echo "$size * 0.10" | bc)
                ebs_cost=$(echo "$ebs_cost + $vol_cost" | bc)
            fi
        done <<< "$ebs_volumes"
        
        if [ "$volume_count" -gt 0 ]; then
            echo -e "${RED}💾 EBS Volumes: $volume_count active${NC}"
            echo -e "   💰 Cost: \$${ebs_cost}/month"
            total_cost=$(echo "$total_cost + $ebs_cost" | bc)
            resources_found=true
        fi
    fi
    
    # Check NAT Gateways
    nat_gateways=$(aws ec2 describe-nat-gateways --region "$REGION" --filter "Name=state,Values=available" --query 'NatGateways[?contains(Tags[?Key==`kubernetes.io/cluster/my-eks-cluster`].Value, `owned`)].NatGatewayId' --output text 2>/dev/null || echo "")
    nat_count=$(echo $nat_gateways | wc -w)
    if [ "$nat_count" -gt 0 ]; then
        echo -e "${RED}🌉 NAT Gateways: $nat_count active${NC}"
        nat_cost=$(echo "$nat_count * 45.00" | bc)
        echo -e "   💰 Cost: \$${nat_cost}/month (\$45.00 each)"
        total_cost=$(echo "$total_cost + $nat_cost" | bc)
        resources_found=true
    fi
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ "$resources_found" = true ]; then
        echo -e "${RED}💸 TOTAL ESTIMATED MONTHLY COST: \$${total_cost}${NC}"
        echo -e "${RED}💸 YEARLY COST: \$$(echo "$total_cost * 12" | bc)${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  These resources are actively incurring charges!${NC}"
        echo -e "${CYAN}Use './eks-manager.sh destroy' to delete all resources${NC}"
    else
        echo -e "${GREEN}✅ No active EKS resources found - No charges!${NC}"
    fi
}

# Function to show cost optimization tips
show_cost_tips() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                💡 COST OPTIMIZATION TIPS 💡               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1. 🗑️  Delete unused resources:${NC}"
    echo "   ./eks-manager.sh destroy"
    echo ""
    echo -e "${CYAN}2. 📊 Scale down Fargate pods:${NC}"
    echo "   kubectl scale deployment <deployment-name> --replicas=1"
    echo ""
    echo -e "${CYAN}3. ⚖️  Remove unnecessary LoadBalancers:${NC}"
    echo "   kubectl delete service <service-name>"
    echo ""
    echo -e "${CYAN}4. 💾 Clean up unused EBS volumes:${NC}"
    echo "   kubectl delete pvc <pvc-name>"
    echo ""
    echo -e "${CYAN}5. 🔄 Use pod autoscaling:${NC}"
    echo "   kubectl apply -f manifests/hpa-config.yaml"
    echo ""
}

# Function to setup billing alerts
setup_billing_alerts() {
    echo -e "${BLUE}Setting up AWS billing alerts...${NC}"
    echo ""
    echo -e "${YELLOW}This will create CloudWatch billing alarms${NC}"
    read -p "Do you want to setup billing alerts? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create SNS topic for billing alerts
        topic_arn=$(aws sns create-topic --name "EKS-Billing-Alerts" --region us-east-1 --query 'TopicArn' --output text 2>/dev/null || echo "")
        
        if [ ! -z "$topic_arn" ]; then
            echo -e "${GREEN}✅ Created SNS topic: $topic_arn${NC}"
            
            # Ask for email
            read -p "Enter your email for billing alerts: " email
            
            if [ ! -z "$email" ]; then
                aws sns subscribe --topic-arn "$topic_arn" --protocol email --notification-endpoint "$email" --region us-east-1
                echo -e "${GREEN}✅ Subscribed $email to billing alerts${NC}"
                echo -e "${YELLOW}Check your email and confirm the subscription${NC}"
                
                # Create billing alarm
                aws cloudwatch put-metric-alarm \
                    --alarm-name "EKS-Monthly-Cost-Alert" \
                    --alarm-description "Alert when EKS costs exceed $200/month" \
                    --metric-name EstimatedCharges \
                    --namespace AWS/Billing \
                    --statistic Maximum \
                    --period 86400 \
                    --threshold 200 \
                    --comparison-operator GreaterThanThreshold \
                    --dimensions Name=Currency,Value=USD \
                    --evaluation-periods 1 \
                    --alarm-actions "$topic_arn" \
                    --region us-east-1
                
                echo -e "${GREEN}✅ Created billing alarm for \$200/month threshold${NC}"
            fi
        fi
    fi
}

# Main menu
echo -e "${YELLOW}Select an option:${NC}"
echo "1. 🔍 Check current resource costs"
echo "2. 💡 Show cost optimization tips"
echo "3. 🚨 Setup billing alerts"
echo "4. 🧹 Quick cleanup (delete all resources)"
echo "5. 📊 View AWS Cost Explorer (opens browser)"
echo ""
read -p "Choose option (1-5): " -n 1 -r choice
echo ""
echo ""

case $choice in
    1)
        check_running_resources
        show_cost_tips
        ;;
    2)
        show_cost_tips
        ;;
    3)
        setup_billing_alerts
        ;;
    4)
        echo -e "${RED}Quick cleanup selected${NC}"
        ../scripts/cleanup-all-resources.sh
        ;;
    5)
        echo -e "${BLUE}Opening AWS Cost Explorer...${NC}"
        xdg-open "https://console.aws.amazon.com/cost-management/home#/cost-explorer" 2>/dev/null || echo "Open: https://console.aws.amazon.com/cost-management/home#/cost-explorer"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}💡 Pro Tip: Run this script regularly to monitor your AWS costs!${NC}"
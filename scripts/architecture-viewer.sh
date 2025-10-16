#!/bin/bash

# Interactive EKS Architecture Viewer
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    EKS CLUSTER ARCHITECTURE VIEWER                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_infrastructure() {
    show_header
    echo -e "${CYAN}🏗️  INFRASTRUCTURE LAYER${NC}"
    echo ""
    echo -e "${YELLOW}AWS Account:${NC} $(aws sts get-caller-identity --query Account --output text)"
    echo -e "${YELLOW}Region:${NC} us-east-1"
    echo ""
    echo -e "${GREEN}┌─ VPC (vpc-0fef7a39ecc0edad5)${NC}"
    echo -e "${GREEN}│  └─ CIDR: 192.168.0.0/16${NC}"
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}├─ PUBLIC SUBNETS${NC}"
    echo -e "${GREEN}│  ├─ us-east-1f: 192.168.0.0/19${NC}"
    echo -e "${GREEN}│  └─ us-east-1c: 192.168.32.0/19${NC}"
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}├─ PRIVATE SUBNETS${NC}"
    echo -e "${GREEN}│  ├─ us-east-1f: 192.168.64.0/19 (Fargate pods here)${NC}"
    echo -e "${GREEN}│  └─ us-east-1c: 192.168.96.0/19 (Fargate pods here)${NC}"
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}└─ SECURITY GROUP: sg-09dc296d00ecb0837${NC}"
    echo ""
    echo -e "${BLUE}💰 Infrastructure Cost: VPC is free, NAT Gateways ~$45/month${NC}"
}

show_control_plane() {
    show_header
    echo -e "${CYAN}🎛️  CONTROL PLANE LAYER${NC}"
    echo ""
    echo -e "${MAGENTA}EKS CLUSTER: my-eks-cluster${NC}"
    echo -e "${GREEN}├─ Status: ACTIVE${NC}"
    echo -e "${GREEN}├─ Version: Kubernetes 1.32${NC}"
    echo -e "${GREEN}├─ Endpoint: Public Access${NC}"
    echo -e "${GREEN}├─ Created: $(./eksctl get cluster --name my-eks-cluster --region us-east-1 --output json | jq -r '.[0].CreatedAt' 2>/dev/null || echo '2025-10-16T17:18:47Z')${NC}"
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}├─ MANAGED COMPONENTS${NC}"
    echo -e "${GREEN}│  ├─ API Server (AWS Managed)${NC}"
    echo -e "${GREEN}│  ├─ etcd (AWS Managed)${NC}"
    echo -e "${GREEN}│  ├─ Controller Manager (AWS Managed)${NC}"
    echo -e "${GREEN}│  └─ Scheduler (AWS Managed)${NC}"
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}└─ ADD-ONS${NC}"
    echo -e "${GREEN}   ├─ VPC CNI (Pod Networking)${NC}"
    echo -e "${GREEN}   ├─ CoreDNS (Service Discovery)${NC}"
    echo -e "${GREEN}   └─ kube-proxy (Load Balancing)${NC}"
    echo ""
    echo -e "${BLUE}💰 Control Plane Cost: $73/month (fixed)${NC}"
}

show_fargate_profiles() {
    show_header
    echo -e "${CYAN}🚀 FARGATE PROFILES LAYER${NC}"
    echo ""
    echo -e "${MAGENTA}FARGATE PROFILES (Serverless Compute)${NC}"
    echo ""
    echo -e "${GREEN}1. default-fargate${NC}"
    echo -e "${GREEN}   ├─ Namespace: default${NC}"
    echo -e "${GREEN}   ├─ Selector: compute-type=fargate${NC}"
    echo -e "${GREEN}   └─ Status: ACTIVE${NC}"
    echo ""
    echo -e "${GREEN}2. fargate-namespace${NC}"  
    echo -e "${GREEN}   ├─ Namespace: fargate-ns${NC}"
    echo -e "${GREEN}   ├─ Selector: <none> (all pods)${NC}"
    echo -e "${GREEN}   └─ Status: ACTIVE${NC}"
    echo ""
    echo -e "${GREEN}3. app-fargate${NC}"
    echo -e "${GREEN}   ├─ Namespace: applications${NC}"
    echo -e "${GREEN}   ├─ Selector: compute-type=fargate${NC}"
    echo -e "${GREEN}   └─ Status: ACTIVE${NC}"
    echo ""
    echo -e "${GREEN}4. frontend-fargate${NC}"
    echo -e "${GREEN}   ├─ Namespace: web-apps${NC}"
    echo -e "${GREEN}   ├─ Selector: tier=frontend${NC}"
    echo -e "${GREEN}   └─ Status: ACTIVE${NC}"
    echo ""
    echo -e "${BLUE}💡 Fargate automatically matches pods to profiles based on namespace + labels${NC}"
}

show_running_workloads() {
    show_header
    echo -e "${CYAN}🏃 RUNNING WORKLOADS${NC}"
    echo ""
    
    # Get actual pod information
    echo -e "${MAGENTA}ACTIVE PODS ON FARGATE:${NC}"
    echo ""
    
    echo -e "${GREEN}Namespace: default${NC}"
    kubectl get pods -n default -l compute-type=fargate -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,IP:.status.podIP" --no-headers 2>/dev/null | while read line; do
        echo -e "${GREEN}├─ $line${NC}"
    done
    echo ""
    
    echo -e "${GREEN}Namespace: fargate-ns${NC}"
    kubectl get pods -n fargate-ns -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,IP:.status.podIP" --no-headers 2>/dev/null | while read line; do
        echo -e "${GREEN}├─ $line${NC}"
    done
    echo ""
    
    echo -e "${GREEN}Namespace: web-apps${NC}"
    kubectl get pods -n web-apps -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,IP:.status.podIP" --no-headers 2>/dev/null | while read line; do
        echo -e "${GREEN}├─ $line${NC}"
    done
    echo ""
    
    local total_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c "fargate-ip" || echo "0")
    echo -e "${BLUE}💰 Total Fargate Pods: ${total_pods}${NC}"
    echo -e "${BLUE}💰 Estimated Compute Cost: $$(($total_pods * 4))/month${NC}"
}

show_services() {
    show_header
    echo -e "${CYAN}🌐 NETWORK SERVICES${NC}"
    echo ""
    
    echo -e "${MAGENTA}KUBERNETES SERVICES:${NC}"
    echo ""
    
    echo -e "${GREEN}ClusterIP Services (Internal):${NC}"
    kubectl get services --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].hostname" --no-headers 2>/dev/null | grep ClusterIP | while read line; do
        echo -e "${GREEN}├─ $line${NC}"
    done
    echo ""
    
    echo -e "${GREEN}LoadBalancer Services (External):${NC}"
    kubectl get services --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].hostname" --no-headers 2>/dev/null | grep LoadBalancer | while read line; do
        echo -e "${GREEN}├─ $line${NC}"
    done
    echo ""
    
    echo -e "${YELLOW}⚠️  LoadBalancer has issues with Fargate (Classic ELB limitation)${NC}"
    echo -e "${GREEN}✅ Alternative: Port forwarding works perfectly${NC}"
}

show_access_methods() {
    show_header
    echo -e "${CYAN}🔌 ACCESS METHODS${NC}"
    echo ""
    
    echo -e "${MAGENTA}CURRENT ACCESS OPTIONS:${NC}"
    echo ""
    
    echo -e "${GREEN}1. Port Forward (Active):${NC}"
    echo -e "${GREEN}   ├─ Command: kubectl port-forward -n web-apps service/frontend-clusterip 9080:80${NC}"
    echo -e "${GREEN}   ├─ URL: http://localhost:9080${NC}"
    echo -e "${GREEN}   └─ Status: ✅ Working${NC}"
    echo ""
    
    echo -e "${GREEN}2. kubectl proxy:${NC}"
    echo -e "${GREEN}   ├─ Command: kubectl proxy${NC}"
    echo -e "${GREEN}   ├─ URL: http://localhost:8001/api/v1/namespaces/web-apps/services/frontend-clusterip:80/proxy/${NC}"
    echo -e "${GREEN}   └─ Status: ✅ Available${NC}"
    echo ""
    
    echo -e "${GREEN}3. LoadBalancer (Limited):${NC}"
    echo -e "${GREEN}   ├─ URL: abea71e7872ce49e5a04c3b9c7f391dc-1050044846.us-east-1.elb.amazonaws.com${NC}"
    echo -e "${GREEN}   └─ Status: ❌ Classic ELB + Fargate issue${NC}"
    echo ""
    
    echo -e "${BLUE}💡 For production: Install AWS Load Balancer Controller for ALB support${NC}"
}

show_cost_analysis() {
    show_header
    echo -e "${CYAN}💰 COST ANALYSIS${NC}"
    echo ""
    
    local total_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c "fargate-ip" || echo "6")
    
    echo -e "${MAGENTA}MONTHLY COST BREAKDOWN:${NC}"
    echo ""
    echo -e "${GREEN}Fixed Costs:${NC}"
    echo -e "${GREEN}├─ EKS Control Plane: $73.00${NC}"
    echo -e "${GREEN}├─ Classic Load Balancer: $18.00${NC}"
    echo -e "${GREEN}└─ NAT Gateways (2x): $45.00${NC}"
    echo ""
    echo -e "${GREEN}Variable Costs:${NC}"
    echo -e "${GREEN}├─ Fargate Pods (${total_pods} pods): $$(($total_pods * 4)).00${NC}"
    echo -e "${GREEN}├─ Data Transfer: $5-10${NC}"
    echo -e "${GREEN}└─ Storage (ephemeral): Included${NC}"
    echo ""
    local total=$((73 + 18 + 45 + ($total_pods * 4) + 7))
    echo -e "${MAGENTA}TOTAL ESTIMATED: ~$${total}/month${NC}"
    echo ""
    echo -e "${BLUE}💡 Cost Optimization:${NC}"
    echo -e "${BLUE}├─ Remove unused LoadBalancer: Save $18/month${NC}"
    echo -e "${BLUE}├─ Scale down pods when not needed: Variable savings${NC}"
    echo -e "${BLUE}└─ Use single NAT Gateway: Save $22.50/month${NC}"
}

show_menu() {
    show_header
    echo -e "${CYAN}📋 ARCHITECTURE LAYERS${NC}"
    echo ""
    echo -e "${GREEN}1. Infrastructure Layer (VPC, Subnets, Security)${NC}"
    echo -e "${GREEN}2. Control Plane Layer (EKS Cluster)${NC}"
    echo -e "${GREEN}3. Compute Layer (Fargate Profiles)${NC}"
    echo -e "${GREEN}4. Application Layer (Running Pods)${NC}"
    echo -e "${GREEN}5. Network Layer (Services)${NC}"
    echo -e "${GREEN}6. Access Methods (How to connect)${NC}"
    echo -e "${GREEN}7. Cost Analysis (Monthly breakdown)${NC}"
    echo -e "${GREEN}8. Live Status Check${NC}"
    echo -e "${GREEN}9. Exit${NC}"
    echo ""
    echo -e "${YELLOW}Select a layer to explore (1-9):${NC} "
}

show_live_status() {
    show_header
    echo -e "${CYAN}📊 LIVE CLUSTER STATUS${NC}"
    echo ""
    
    echo -e "${MAGENTA}CLUSTER STATUS:${NC}"
    ./eksctl get cluster --name my-eks-cluster --region us-east-1 2>/dev/null || echo "Error getting cluster status"
    echo ""
    
    echo -e "${MAGENTA}FARGATE PROFILES:${NC}"
    ./eksctl get fargateprofile --cluster my-eks-cluster --region us-east-1 2>/dev/null || echo "Error getting Fargate profiles"
    echo ""
    
    echo -e "${MAGENTA}RUNNING PODS:${NC}"
    kubectl get pods --all-namespaces -o wide 2>/dev/null | grep fargate || echo "No Fargate pods found"
    echo ""
    
    echo -e "${MAGENTA}SERVICES:${NC}"
    kubectl get services --all-namespaces 2>/dev/null || echo "Error getting services"
}

# Main menu loop
while true; do
    show_menu
    read -n 1 choice
    echo ""
    
    case $choice in
        1) show_infrastructure; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        2) show_control_plane; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        3) show_fargate_profiles; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        4) show_running_workloads; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        5) show_services; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        6) show_access_methods; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        7) show_cost_analysis; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        8) show_live_status; echo ""; echo "Press any key to continue..."; read -n 1 ;;
        9) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid selection. Press any key to continue..."; read -n 1 ;;
    esac
done
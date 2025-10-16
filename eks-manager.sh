#!/bin/bash

# EKS Cluster Management Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="my-eks-cluster"
REGION="us-east-1"

# Navigate to project directory
cd /home/abid/Project/AWS-Project

show_help() {
    echo -e "${BLUE}EKS Cluster Management Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  create     Create a new EKS cluster"
    echo "  delete     Delete the EKS cluster"
    echo "  status     Show cluster status"
    echo "  nodes      Show cluster nodes"
    echo "  pods       Show all pods"
    echo "  services   Show all services"
    echo "  test       Deploy test application"
    echo "  cleanup    Remove test applications"
    echo "  fargate    Setup Fargate profiles"
    echo "  fargate-test Deploy Fargate test apps"
    echo "  fargate-clean Clean Fargate test apps"
    echo "  help       Show this help message"
}

create_cluster() {
    echo -e "${YELLOW}Creating EKS cluster...${NC}"
    ./scripts/create-simple-cluster.sh
}

delete_cluster() {
    echo -e "${RED}Deleting EKS cluster...${NC}"
    read -p "Are you sure you want to delete the cluster? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./eksctl delete cluster --name $CLUSTER_NAME --region $REGION
        echo -e "${GREEN}Cluster deleted successfully!${NC}"
    else
        echo -e "${YELLOW}Cluster deletion cancelled.${NC}"
    fi
}

show_status() {
    echo -e "${BLUE}=== Cluster Status ===${NC}"
    kubectl cluster-info
    echo ""
    echo -e "${BLUE}=== Cluster Details ===${NC}"
    ./eksctl get cluster --name $CLUSTER_NAME --region $REGION
}

show_nodes() {
    echo -e "${BLUE}=== Cluster Nodes ===${NC}"
    kubectl get nodes -o wide
}

show_pods() {
    echo -e "${BLUE}=== All Pods ===${NC}"
    kubectl get pods --all-namespaces -o wide
}

show_services() {
    echo -e "${BLUE}=== All Services ===${NC}"
    kubectl get services --all-namespaces -o wide
}

deploy_test() {
    echo -e "${YELLOW}Deploying test applications...${NC}"
    kubectl apply -f manifests/test-pod.yaml
    kubectl apply -f manifests/nginx-deployment.yaml
    echo -e "${GREEN}Test applications deployed!${NC}"
    echo ""
    echo -e "${BLUE}Wait a few moments and check status:${NC}"
    echo "kubectl get pods"
    echo "kubectl get services"
}

cleanup_test() {
    echo -e "${YELLOW}Cleaning up test applications...${NC}"
    kubectl delete -f manifests/test-pod.yaml --ignore-not-found
    kubectl delete -f manifests/nginx-deployment.yaml --ignore-not-found
    echo -e "${GREEN}Test applications cleaned up!${NC}"
}

setup_fargate() {
    echo -e "${YELLOW}Setting up Fargate profiles...${NC}"
    ./scripts/setup-fargate.sh
}

deploy_fargate_test() {
    echo -e "${YELLOW}Deploying Fargate test applications...${NC}"
    kubectl apply -f manifests/fargate-test-pod.yaml
    kubectl apply -f manifests/fargate-app.yaml
    kubectl apply -f manifests/frontend-fargate.yaml
    echo -e "${GREEN}Fargate test applications deployed!${NC}"
    echo ""
    echo -e "${BLUE}Check Fargate pods:${NC}"
    echo "kubectl get pods -n default -l compute-type=fargate"
    echo "kubectl get pods -n fargate-ns"
    echo "kubectl get pods -n web-apps -l tier=frontend"
}

cleanup_fargate_test() {
    echo -e "${YELLOW}Cleaning up Fargate test applications...${NC}"
    kubectl delete -f manifests/fargate-test-pod.yaml --ignore-not-found
    kubectl delete -f manifests/fargate-app.yaml --ignore-not-found
    kubectl delete -f manifests/frontend-fargate.yaml --ignore-not-found
    echo -e "${GREEN}Fargate test applications cleaned up!${NC}"
}

case "${1:-help}" in
    create)
        create_cluster
        ;;
    delete)
        delete_cluster
        ;;
    status)
        show_status
        ;;
    nodes)
        show_nodes
        ;;
    pods)
        show_pods
        ;;
    services)
        show_services
        ;;
    test)
        deploy_test
        ;;
    cleanup)
        cleanup_test
        ;;
    fargate)
        setup_fargate
        ;;
    fargate-test)
        deploy_fargate_test
        ;;
    fargate-clean)
        cleanup_fargate_test
        ;;
    help|*)
        show_help
        ;;
esac
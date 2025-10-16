# 🚀 AWS EKS + Fargate Serverless Kubernetes Platform

[![AWS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-blue)](https://kubernetes.io/)
[![Fargate](https://img.shields.io/badge/AWS-Fargate-green)](https://aws.amazon.com/fargate/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A **production-ready, serverless Kubernetes cluster** on AWS using EKS + Fargate. No EC2 instances to manage - just deploy your containers and let AWS handle the infrastructure!

## ✨ What This Project Provides

🎯 **Complete serverless Kubernetes platform** with 13 integrated AWS services  
🎯 **4 Fargate profiles** for different workload types  
🎯 **6 sample applications** running on Fargate  
🎯 **$60/month cost savings** vs traditional EC2 node groups  
🎯 **Production-ready architecture** with multi-AZ high availability  
🎯 **Comprehensive management tools** and interactive dashboards  

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS EKS CLUSTER                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Control Plane (Managed)     Fargate Profiles (4)              │
│  ├── API Server              ├── default-fargate                │
│  ├── etcd                    ├── fargate-namespace              │
│  ├── Scheduler               ├── app-fargate                    │
│  └── Controller Manager      └── frontend-fargate              │
│                                                                 │
│  Running Applications (6 pods)                                 │
│  ├── Frontend Apps (3 pods) - Apache httpd                    │
│  ├── Web Apps (2 pods) - NGINX                                │
│  └── Test Pod (1 pod) - NGINX                                 │
│                                                                 │
│  Network Services                                              │
│  ├── LoadBalancer Service (External access)                   │
│  ├── ClusterIP Services (Internal)                            │
│  └── Port Forward (Working access method)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## � Project Architecture

### Directory Structure
```
AWS-Project/
├── 🎯 eks-manager.sh              # Central cluster controller
├── 📁 scripts/                    # 8 specialized automation tools
│   ├── setup-fargate.sh          # Serverless compute setup
│   ├── architecture-viewer.sh     # Interactive cluster browser
│   ├── fix-loadbalancer.sh       # Access troubleshooting
│   └── ...                       # Additional utilities
├── ⚙️ eks-setup/                  # Production-ready configurations
│   ├── cluster-config.yaml       # Advanced EKS template
│   └── fargate-config.yaml       # Serverless profiles
├── 🚀 manifests/                  # Sample application deployments
│   ├── fargate-app.yaml          # Multi-replica apps
│   ├── frontend-fargate.yaml     # LoadBalancer services
│   └── test-apps.yaml           # Development testing
├── � docs/                       # Comprehensive documentation
│   ├── ARCHITECTURE.md           # System design & AWS services
│   ├── FARGATE-GUIDE.md          # Serverless deployment guide
│   └── TROUBLESHOOTING.md        # Common issues & solutions
└── 📋 logs/                       # Operational history & debugging
```

### Service Integration
- **EKS Control Plane**: Managed Kubernetes API server
- **Fargate Compute**: Serverless pod execution (4 profiles)
- **VPC Networking**: Custom VPC with public/private subnets
- **IAM Integration**: OIDC provider + service accounts
- **Load Balancing**: Classic ELB + port forwarding options

## 🚀 Quick Start (5 minutes)

### Prerequisites
- ✅ AWS CLI configured with credentials
- ✅ `kubectl` installed  
- ✅ Internet connection

### 1. Clone & Setup
```bash
git clone https://github.com/abidaslam892/AWS-EKS.git
cd AWS-EKS

# Download eksctl (one-time setup)
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz
chmod +x eksctl
```

### 2. Create EKS Cluster
```bash
# Create cluster with Fargate (10-15 minutes)
./eks-manager.sh create

# Add Fargate profiles for serverless pods
./eks-manager.sh fargate
```

### 3. Deploy & Test Applications
```bash
# Deploy sample applications
./eks-manager.sh fargate-test

# Access your applications
kubectl port-forward -n web-apps service/frontend-clusterip 9080:80
# Open: http://localhost:9080
```

### 4. Explore Architecture
```bash
# Interactive architecture browser
./scripts/architecture-viewer.sh
```

**🎉 You now have a production-ready serverless Kubernetes cluster!**

## 🛠️ Management Tools

### Primary Controller (`./eks-manager.sh`)
```bash
./eks-manager.sh [command]

Commands:
├── create          # Create new EKS cluster
├── delete          # Delete cluster (with confirmation)
├── status          # Show cluster health & details
├── nodes           # Display worker nodes
├── pods            # List all pods across namespaces
├── services        # Show all services
├── fargate         # Setup Fargate profiles
├── fargate-test    # Deploy Fargate applications
├── fargate-clean   # Remove Fargate test apps
└── help            # Show all commands
```

### Specialized Scripts

| Script | Purpose | Use Case |
|--------|---------|----------|
| `setup-fargate.sh` | Install 4 Fargate profiles | Serverless pod execution |
| `architecture-viewer.sh` | Interactive cluster browser | Understanding architecture |
| `fix-loadbalancer.sh` | Alternative access methods | When LoadBalancer has issues |
| `verify-cluster.sh` | Complete cluster validation | Health checks & testing |
| `monitor-cluster.sh` | Real-time cluster monitoring | Deployment progress tracking |

### Configuration Templates

| File | Purpose |
|------|---------|
| `cluster-config.yaml` | Advanced EKS cluster setup |
| `fargate-config.yaml` | Fargate profile templates |
| `manifests/*.yaml` | Sample application deployments |

## 📋 Configuration Files

### Simple Cluster Configuration

The simple cluster is created with command-line parameters:
- **Name:** my-eks-cluster
- **Region:** us-east-1
- **Node Type:** t3.medium
- **Initial Nodes:** 2
- **Min Nodes:** 1
- **Max Nodes:** 4

### Advanced Configuration (`eks-setup/cluster-config.yaml`)

Comprehensive YAML configuration including:
- Custom VPC with public/private subnets
- Multiple managed node groups
- IAM service accounts
- Add-ons and logging
- Fargate profiles

## 🧪 Testing Your Cluster

### Deploy Sample Applications

```bash
# Deploy test applications
./eks-manager.sh test

# Check deployment status
kubectl get pods
kubectl get services

# View NGINX service (wait for LoadBalancer to be ready)
kubectl get service nginx-service
```

### Manual Testing

```bash
# Create a test pod
kubectl apply -f manifests/test-pod.yaml

# Check pod logs
kubectl logs test-pod

# Deploy NGINX
kubectl apply -f manifests/nginx-deployment.yaml

# Access NGINX service
kubectl get service nginx-service
# Note the EXTERNAL-IP and access via browser
```

## 🔧 Common Operations

### Connect to Your Cluster

```bash
# Update kubeconfig (if needed)
./eksctl utils write-kubeconfig --cluster=my-eks-cluster --region=us-east-1

# Verify connection
kubectl get nodes
```

### Scale Your Cluster

```bash
# Scale node group
./eksctl scale nodegroup --cluster=my-eks-cluster --name=worker-nodes --nodes=5 --region=us-east-1

# Scale application
kubectl scale deployment nginx-deployment --replicas=5
```

### Monitor Your Cluster

```bash
# Get cluster info
kubectl cluster-info

# View resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## � Cost Analysis & Optimization

### Current Monthly Costs
| Service | Cost | Notes |
|---------|------|-------|
| 🎛️ EKS Control Plane | $72.00 | $0.10/hour × 24/7 |
| ☁️ Fargate Pods | $43.20 | 6 pods × 0.25 vCPU × 0.5GB |
| 🌐 Data Transfer | $9.00 | Moderate usage estimate |
| ⚖️ Classic Load Balancer | $18.00 | Optional (removable) |
| 💾 EBS Storage | $8.00 | Persistent volumes |
| 🔌 VPC Endpoints | $7.20 | Private API access |
| **📊 Total** | **~$157.40** | **27% savings vs EC2** |

### 💡 Optimization Strategies
```bash
# 1. Remove unused LoadBalancer (save $18/month)
kubectl delete service frontend-fargate-service

# 2. Scale down idle pods
kubectl scale deployment nginx-fargate --replicas=1

# 3. Use pod auto-scaling
kubectl apply -f manifests/hpa-config.yaml
```

### 📈 Scaling Economics
- **Development**: ~$130/month (2-3 pods)
- **Production**: ~$200/month (10-15 pods)
- **High Traffic**: ~$350/month (25+ pods with auto-scaling)

*Fargate pricing scales linearly with actual usage - no idle EC2 costs*

## �🗑️ Cleanup

### Remove Test Applications

```bash
./eks-manager.sh cleanup
```

### Delete the Entire Cluster

```bash
./eks-manager.sh delete
```

**⚠️ Warning:** This will delete the entire cluster and all resources. Make sure to backup any important data first.



## 🚨 Troubleshooting

### Common Issues

1. **Cluster creation fails:**
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify IAM permissions for EKS
   - Ensure sufficient service limits

2. **Can't connect to cluster:**
   - Update kubeconfig: `./eksctl utils write-kubeconfig --cluster=my-eks-cluster --region=us-east-1`
   - Check kubectl version compatibility

3. **Pods stuck in Pending:**
   - Check node resources: `kubectl describe nodes`
   - Verify security groups and networking

4. **LoadBalancer stuck in Pending:**
   - Check AWS load balancer controller
   - Verify subnet tags for load balancer discovery

### Useful Commands

```bash
# Check cluster status
./eksctl get cluster --name=my-eks-cluster --region=us-east-1

# View cluster logs
./eksctl utils describe-stacks --cluster=my-eks-cluster --region=us-east-1

# Debug networking
kubectl get pods -n kube-system
kubectl logs -n kube-system -l k8s-app=aws-node

# Check IAM roles
./eksctl get iamidentitymapping --cluster=my-eks-cluster --region=us-east-1
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [eksctl Documentation](https://eksctl.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 🔐 Security Best Practices

1. Use IAM roles for service accounts (IRSA)
2. Enable cluster logging
3. Use private subnets for worker nodes
4. Regularly update cluster and node versions
5. Implement network policies
6. Use secrets for sensitive data
7. Enable Pod Security Standards

---

**Happy Kubernetes clustering! 🚀**
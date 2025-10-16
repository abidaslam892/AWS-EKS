# AWS EKS Project

This project contains all the necessary configurations and scripts to set up and manage an Amazon EKS (Elastic Kubernetes Service) cluster.

## 📁 Project Structure

```
AWS-Project/
├── eks-setup/
│   └── cluster-config.yaml      # Comprehensive EKS cluster configuration
├── scripts/
│   ├── setup-eks-cluster.sh     # Full-featured cluster setup with add-ons
│   └── create-simple-cluster.sh # Simple cluster creation script
├── manifests/
│   ├── nginx-deployment.yaml    # Sample NGINX deployment
│   └── test-pod.yaml           # Test pod for verification
├── eks-manager.sh              # Cluster management utility
├── eksctl                      # EKS CLI tool (local binary)
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with proper credentials
- kubectl installed
- Internet connection for downloading container images

### Create Your First EKS Cluster

1. **Simple cluster creation (recommended for beginners):**
   ```bash
   ./eks-manager.sh create
   ```

2. **Advanced cluster with all features:**
   ```bash
   ./scripts/setup-eks-cluster.sh
   ```

### Verify Your Cluster

```bash
# Check cluster status
./eks-manager.sh status

# View worker nodes
./eks-manager.sh nodes

# Deploy test applications
./eks-manager.sh test
```

## 🛠️ Available Scripts

### EKS Manager (`./eks-manager.sh`)

Main management script with the following commands:

- `create` - Create a new EKS cluster (simple setup)
- `delete` - Delete the EKS cluster
- `status` - Show cluster status and information
- `nodes` - Display worker nodes
- `pods` - Show all pods across namespaces
- `services` - Display all services
- `test` - Deploy test applications (NGINX + test pod)
- `cleanup` - Remove test applications
- `help` - Show help information

### Setup Scripts

- **`scripts/create-simple-cluster.sh`** - Creates a basic EKS cluster with:
  - 2 worker nodes (t3.medium)
  - Managed node group
  - Basic networking
  - Auto-scaling from 1-4 nodes

- **`scripts/setup-eks-cluster.sh`** - Creates a production-ready cluster with:
  - Custom VPC and subnets
  - Multiple availability zones
  - Service accounts with OIDC
  - Add-ons (EBS CSI, VPC CNI, CoreDNS)
  - CloudWatch logging
  - Fargate profiles
  - Load balancer controller
  - Cluster autoscaler

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

## 🗑️ Cleanup

### Remove Test Applications

```bash
./eks-manager.sh cleanup
```

### Delete the Entire Cluster

```bash
./eks-manager.sh delete
```

**⚠️ Warning:** This will delete the entire cluster and all resources. Make sure to backup any important data first.

## 💰 Cost Considerations

### Estimated Monthly Costs (us-east-1):

- **EKS Control Plane:** ~$73/month
- **Worker Nodes (2x t3.medium):** ~$60/month  
- **EBS Volumes:** ~$10/month
- **Data Transfer:** Variable
- **Load Balancers:** ~$18/month (if using LoadBalancer services)

**Total:** ~$160-180/month for a basic cluster

### Cost Optimization Tips:

1. Use spot instances for non-production workloads
2. Right-size your worker nodes
3. Use cluster autoscaler to scale down when not needed
4. Clean up unused LoadBalancers and EBS volumes

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
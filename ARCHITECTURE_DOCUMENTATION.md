# EKS Cluster Architecture & Services Documentation

## 🏗️ Complete Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS CLOUD (us-east-1)                            │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                          VPC (vpc-0fef7a39ecc0edad5)                    │    │
│  │                            CIDR: 192.168.0.0/16                         │    │
│  │                                                                         │    │
│  │  ┌─────────────────────┐              ┌─────────────────────┐           │    │
│  │  │   PUBLIC SUBNETS    │              │   PRIVATE SUBNETS   │           │    │
│  │  │                     │              │                     │           │    │
│  │  │  us-east-1f         │              │  us-east-1f         │           │    │
│  │  │  192.168.0.0/19     │              │  192.168.64.0/19    │           │    │
│  │  │                     │              │                     │           │    │
│  │  │  us-east-1c         │              │  us-east-1c         │           │    │
│  │  │  192.168.32.0/19    │              │  192.168.96.0/19    │           │    │
│  │  │                     │              │                     │           │    │
│  │  │  ┌─────────────┐    │              │                     │           │    │
│  │  │  │ Internet    │    │              │                     │           │    │
│  │  │  │ Gateway     │    │              │                     │           │    │
│  │  │  └─────────────┘    │              │                     │           │    │
│  │  │                     │              │                     │           │    │
│  │  │  ┌─────────────┐    │              │  ┌─────────────┐    │           │    │
│  │  │  │ Classic ELB │    │              │  │ NAT Gateway │    │           │    │
│  │  │  │ (LoadBalancer)  │              │  │             │    │           │    │
│  │  │  └─────────────┘    │              │  └─────────────┘    │           │    │
│  │  └─────────────────────┘              └─────────────────────┘           │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │  │                    EKS CONTROL PLANE                            │   │    │
│  │  │              (Managed by AWS - Version 1.32)                    │   │    │
│  │  │                                                                 │   │    │
│  │  │  ├── API Server                                                 │   │    │
│  │  │  ├── etcd                                                       │   │    │
│  │  │  ├── Controller Manager                                         │   │    │
│  │  │  └── Scheduler                                                  │   │    │
│  │  └─────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │  │                    FARGATE COMPUTE                              │   │    │
│  │  │                  (Serverless Pods)                             │   │    │
│  │  │                                                                 │   │    │
│  │  │  Namespace: default                                             │   │    │
│  │  │  ┌─────────────────────────┐                                   │   │    │
│  │  │  │ fargate-test-pod        │                                   │   │    │
│  │  │  │ Image: nginx:1.20       │                                   │   │    │
│  │  │  │ CPU: 0.25, RAM: 0.5GB   │                                   │   │    │
│  │  │  │ Label: compute-type=fargate                                 │   │    │
│  │  │  └─────────────────────────┘                                   │   │    │
│  │  │                                                                 │   │    │
│  │  │  Namespace: fargate-ns                                          │   │    │
│  │  │  ┌─────────────────────────┐ ┌─────────────────────────┐       │   │    │
│  │  │  │ fargate-web-app-1       │ │ fargate-web-app-2       │       │   │    │
│  │  │  │ Image: nginx:1.20       │ │ Image: nginx:1.20       │       │   │    │
│  │  │  │ CPU: 0.25, RAM: 0.5GB   │ │ CPU: 0.25, RAM: 0.5GB   │       │   │    │
│  │  │  └─────────────────────────┘ └─────────────────────────┘       │   │    │
│  │  │                                                                 │   │    │
│  │  │  Namespace: web-apps                                            │   │    │
│  │  │  ┌─────────────────────────┐ ┌─────────────────────────┐       │   │    │
│  │  │  │ frontend-app-1          │ │ frontend-app-2          │       │   │    │
│  │  │  │ Image: httpd:2.4        │ │ Image: httpd:2.4        │       │   │    │
│  │  │  │ CPU: 0.25, RAM: 0.5GB   │ │ CPU: 0.25, RAM: 0.5GB   │       │   │    │
│  │  │  │ Label: tier=frontend    │ │ Label: tier=frontend    │       │   │    │
│  │  │  └─────────────────────────┘ └─────────────────────────┘       │   │    │
│  │  │                                                                 │   │    │
│  │  │  ┌─────────────────────────┐                                   │   │    │
│  │  │  │ frontend-app-3          │                                   │   │    │
│  │  │  │ Image: httpd:2.4        │                                   │   │    │
│  │  │  │ CPU: 0.25, RAM: 0.5GB   │                                   │   │    │
│  │  │  │ Label: tier=frontend    │                                   │   │    │
│  │  │  └─────────────────────────┘                                   │   │    │
│  │  └─────────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                           IAM ROLES                                 │    │
│  │                                                                     │    │
│  │  ├── EKS Cluster Service Role                                       │    │
│  │  ├── Fargate Pod Execution Role                                     │    │
│  │  └── OIDC Identity Provider                                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              LOCAL ACCESS                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Your Computer                                                                  │
│  ┌─────────────────────────┐              ┌─────────────────────────┐           │
│  │    kubectl              │   Port       │    Web Browser         │           │
│  │  ┌─────────────────┐    │   Forward    │  ┌─────────────────┐    │           │
│  │  │ ~/.kube/config  │────┼──────────────┼──│localhost:9080   │    │           │
│  │  └─────────────────┘    │              │  └─────────────────┘    │           │
│  └─────────────────────────┘              └─────────────────────────┘           │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📋 Detailed Service Inventory

### 🏢 **Infrastructure Services**

#### 1. **EKS Control Plane** (`my-eks-cluster`)
- **What:** Managed Kubernetes control plane
- **Why Created:** Provides the Kubernetes API server, scheduler, and controller manager
- **Details:**
  - Version: 1.32
  - Status: ACTIVE
  - Endpoint: Public access enabled
  - Region: us-east-1
  - Cost: ~$73/month

#### 2. **VPC & Networking**
- **What:** Custom VPC with public/private subnets
- **Why Created:** Provides isolated network environment for EKS cluster
- **Details:**
  - VPC ID: `vpc-0fef7a39ecc0edad5`
  - CIDR: `192.168.0.0/16`
  - Subnets: 4 subnets across 2 AZs
  - Internet Gateway: For public subnet internet access
  - NAT Gateways: For private subnet outbound internet access

### 🚀 **Compute Services (Fargate)**

#### 3. **Fargate Profiles**
- **What:** Serverless compute profiles for running pods
- **Why Created:** Eliminates need for EC2 instance management
- **Details:**

| Profile Name | Namespace | Selector | Purpose |
|-------------|-----------|----------|---------|
| `default-fargate` | `default` | `compute-type=fargate` | Development/testing pods |
| `fargate-namespace` | `fargate-ns` | none | Dedicated Fargate namespace |
| `app-fargate` | `applications` | `compute-type=fargate` | Application workloads |
| `frontend-fargate` | `web-apps` | `tier=frontend` | Frontend applications |

### 📦 **Application Services**

#### 4. **Test Pod** (`fargate-test-pod`)
- **What:** Single NGINX pod for testing
- **Why Created:** Verify Fargate functionality with labeled pods
- **Details:**
  - Namespace: `default`
  - Image: `nginx:1.20`
  - Resources: 0.25 vCPU, 0.5GB RAM
  - Label: `compute-type=fargate`
  - Status: Running on Fargate node

#### 5. **Web Application Deployment** (`fargate-web-app`)
- **What:** 2-replica NGINX deployment
- **Why Created:** Demonstrate multi-pod Fargate deployment
- **Details:**
  - Namespace: `fargate-ns`
  - Replicas: 2
  - Image: `nginx:1.20`
  - Resources: 0.25 vCPU, 0.5GB RAM per pod
  - Status: Running on Fargate nodes

#### 6. **Frontend Application** (`frontend-app`)
- **What:** 3-replica Apache HTTP server deployment
- **Why Created:** Test frontend tier with LoadBalancer service
- **Details:**
  - Namespace: `web-apps`
  - Replicas: 3
  - Image: `httpd:2.4`
  - Resources: 0.25 vCPU, 0.5GB RAM per pod
  - Label: `tier=frontend`
  - Status: Running on Fargate nodes

### 🌐 **Network Services**

#### 7. **ClusterIP Services**
- **What:** Internal cluster networking services
- **Why Created:** Enable pod-to-pod communication within cluster
- **Details:**

| Service Name | Namespace | Type | Purpose |
|-------------|-----------|------|---------|
| `fargate-web-service` | `fargate-ns` | ClusterIP | Internal access to web app |
| `frontend-clusterip` | `web-apps` | ClusterIP | Internal access to frontend |

#### 8. **LoadBalancer Service** (`frontend-service`)
- **What:** AWS Classic Load Balancer
- **Why Created:** Attempt to provide external access (has limitations with Fargate)
- **Details:**
  - Type: LoadBalancer (Classic ELB)
  - External IP: `abea71e7872ce49e5a04c3b9c7f391dc-1050044846.us-east-1.elb.amazonaws.com`
  - Status: Created but no healthy targets (Fargate limitation)
  - Port: 80:30802/TCP

### 🔒 **Security Services**

#### 9. **IAM Roles**
- **What:** AWS IAM roles for cluster operations
- **Why Created:** Secure access and permissions for EKS and Fargate
- **Details:**
  - **EKS Cluster Service Role:** For cluster management
  - **Fargate Pod Execution Role:** For Fargate pod operations
  - **OIDC Provider:** For service account integration

#### 10. **Security Groups**
- **What:** Network firewall rules
- **Why Created:** Control inbound/outbound traffic
- **Details:**
  - ID: `sg-09dc296d00ecb0837`
  - Rules: EKS-managed rules for cluster communication

### 🔧 **System Services**

#### 11. **Core DNS**
- **What:** DNS service running in kube-system namespace
- **Why Created:** Provides DNS resolution within the cluster
- **Details:**
  - Namespace: `kube-system`
  - Type: EKS managed add-on
  - Status: Running

#### 12. **VPC CNI**
- **What:** Container Network Interface plugin
- **Why Created:** Provides pod networking using VPC IPs
- **Details:**
  - Namespace: `kube-system`
  - Type: EKS managed add-on
  - Function: Assigns VPC IPs to pods

#### 13. **kube-proxy**
- **What:** Network proxy service
- **Why Created:** Handles service networking and load balancing
- **Details:**
  - Namespace: `kube-system`
  - Type: EKS managed add-on
  - Function: Service discovery and load balancing

## 🎯 **Service Purpose & Architecture Rationale**

### **Why This Architecture?**

1. **Serverless Approach:** Chose Fargate over EC2 node groups to eliminate server management
2. **Multi-Namespace Design:** Separated workloads by purpose (default, fargate-ns, web-apps)
3. **Multiple Service Types:** Demonstrated different access patterns (ClusterIP, LoadBalancer)
4. **Label-Based Scheduling:** Used labels to control pod placement on Fargate profiles

### **Cost Optimization:**
- **No EC2 instances:** Fargate eliminates idle capacity costs
- **Pay-per-pod:** Only pay for running containers
- **Right-sized resources:** Each pod uses minimal resources (0.25 vCPU, 0.5GB)

### **High Availability:**
- **Multi-AZ deployment:** Pods distributed across availability zones
- **Multiple replicas:** Frontend app has 3 replicas for redundancy
- **Managed control plane:** AWS manages control plane availability

## 📊 **Current Resource Utilization**

```
Total Fargate Pods: 6
├── default namespace: 1 pod (NGINX)
├── fargate-ns namespace: 2 pods (NGINX)
└── web-apps namespace: 3 pods (Apache)

Total vCPU: 1.5 vCPU (6 × 0.25)
Total Memory: 3 GB (6 × 0.5GB)
Storage: 20GB ephemeral per pod (120GB total)

Estimated Monthly Cost:
├── EKS Control Plane: $73
├── Fargate Compute: $20-25
├── Data Transfer: $5-10
└── Total: ~$98-108/month
```

This architecture provides a production-ready, serverless Kubernetes environment with automatic scaling, high availability, and cost optimization through AWS Fargate.
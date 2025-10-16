# Service-by-Service Technical Breakdown

## 🔍 **Deep Dive: Each Service Explained**

### 1. **EKS Control Plane Service**
```yaml
Service Type: AWS EKS Cluster
Resource Name: my-eks-cluster
```

**Technical Details:**
- **API Endpoint:** `https://[cluster-id].gr7.us-east-1.eks.amazonaws.com`
- **Certificate Authority:** AWS-managed TLS certificates
- **Version:** Kubernetes 1.32
- **Add-ons:** VPC CNI, CoreDNS, kube-proxy
- **Logging:** Disabled (can be enabled for audit/API logs)

**Why Created:**
- Central control plane for all Kubernetes operations
- Manages pod scheduling, service discovery, and cluster state
- Provides secure API access for kubectl and applications

**Cost:** $0.10/hour = ~$73/month (fixed cost regardless of workload)

---

### 2. **Fargate Pod Execution Role**
```bash
Role ARN: arn:aws:iam::912606813826:role/eksctl-my-eks-cluster-farga-FargatePodExecutionRole-xJOh4KJJI4lq
```

**Technical Details:**
- **Service:** AWS IAM Role
- **Attached Policies:**
  - `AmazonEKSFargatePodExecutionRolePolicy`
  - `AmazonEKS_CNI_Policy` (for networking)
- **Trust Relationship:** `eks-fargate-pods.amazonaws.com`
- **Purpose:** Allows Fargate to pull container images and write logs on behalf of pods

**Why Created:**
- Required for Fargate to execute pods securely
- Provides necessary permissions for container lifecycle management
- Enables integration with other AWS services (ECR, CloudWatch)

---

### 3. **VPC and Networking Infrastructure**
```yaml
VPC ID: vpc-0fef7a39ecc0edad5
CIDR: 192.168.0.0/16 (65,536 IP addresses)
```

**Subnet Breakdown:**
```
Public Subnets:
├── us-east-1f: 192.168.0.0/19   (8,192 IPs)
└── us-east-1c: 192.168.32.0/19  (8,192 IPs)

Private Subnets:
├── us-east-1f: 192.168.64.0/19  (8,192 IPs)
└── us-east-1c: 192.168.96.0/19  (8,192 IPs)
```

**Network Components:**
- **Internet Gateway:** Enables public subnet internet access
- **NAT Gateways:** 2 gateways for private subnet outbound internet
- **Route Tables:** Separate routing for public/private subnets
- **Security Groups:** `sg-09dc296d00ecb0837` (EKS managed)

**Why This Design:**
- **High Availability:** Resources spread across 2 AZs
- **Security:** Fargate pods run in private subnets
- **Scalability:** Large IP address space for growth
- **AWS Best Practices:** Follows EKS networking recommendations

---

### 4. **Fargate Profile: default-fargate**
```yaml
Profile Name: default-fargate
Namespace: default
Selector: compute-type=fargate
Status: ACTIVE
```

**Technical Configuration:**
```yaml
subnets:
  - subnet-038cd6c2de82a8427  # Private subnet us-east-1f
  - subnet-0a10a94aac611de59  # Private subnet us-east-1c
executionRoleArn: arn:aws:iam::912606813826:role/eksctl-my-eks-cluster-farga-FargatePodExecutionRole-xJOh4KJJI4lq
```

**Pod Matching Rules:**
- Namespace: `default` AND
- Labels: `compute-type=fargate`

**Why Created:**
- Enables serverless execution for development/testing pods
- Provides compute isolation from other workloads
- Supports rapid prototyping without infrastructure planning

---

### 5. **Fargate Profile: fargate-namespace**
```yaml
Profile Name: fargate-namespace
Namespace: fargate-ns
Selector: <none> (all pods in namespace)
Status: ACTIVE
```

**Pod Matching Rules:**
- Namespace: `fargate-ns` (any pod in this namespace)

**Why Created:**
- Dedicated namespace for Fargate-only workloads
- Simplifies deployment (no labels required)
- Clear separation of serverless vs traditional workloads

---

### 6. **Fargate Profile: frontend-fargate**
```yaml
Profile Name: frontend-fargate
Namespace: web-apps
Selector: tier=frontend
Status: ACTIVE
```

**Pod Matching Rules:**
- Namespace: `web-apps` AND
- Labels: `tier=frontend`

**Why Created:**
- Targets frontend application tier specifically
- Enables different compute strategies for different tiers
- Supports microservices architecture patterns

---

### 7. **Application: fargate-test-pod**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fargate-test-pod
  namespace: default
  labels:
    compute-type: fargate
    app: test-fargate
spec:
  containers:
  - name: test-container
    image: nginx:1.20
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Runtime Details:**
- **Fargate Node:** `fargate-ip-192-168-77-14.ec2.internal`
- **Pod IP:** `192.168.77.14`
- **vCPU Allocation:** 0.25 vCPU
- **Memory Allocation:** 0.5 GB
- **Storage:** 20 GB ephemeral

**Why Created:**
- Validates Fargate profile functionality
- Tests label-based pod scheduling
- Simple single-container workload for testing

---

### 8. **Application: fargate-web-app (Deployment)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fargate-web-app
  namespace: fargate-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fargate-web
  template:
    spec:
      containers:
      - name: web-server
        image: nginx:1.20
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
```

**Runtime Details:**
```
Pod 1: fargate-web-app-65c888dbf8-2qllw
├── Node: fargate-ip-192-168-114-104.ec2.internal
├── IP: 192.168.114.104
└── Status: Running

Pod 2: fargate-web-app-65c888dbf8-kzd4f
├── Node: fargate-ip-192-168-101-167.ec2.internal  
├── IP: 192.168.101.167
└── Status: Running
```

**Why Created:**
- Demonstrates multi-replica deployment on Fargate
- Tests automatic pod distribution across AZs
- Provides scalable web application example

---

### 9. **Application: frontend-app (Deployment)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: web-apps
  labels:
    tier: frontend
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: httpd:2.4
```

**Runtime Details:**
```
Pod 1: frontend-app-654d9bcf94-cwxgb
├── Node: fargate-ip-192-168-110-195.ec2.internal
├── IP: 192.168.110.195
└── Content: Apache "It works!" page

Pod 2: frontend-app-654d9bcf94-cxhvg  
├── Node: fargate-ip-192-168-83-44.ec2.internal
├── IP: 192.168.83.44
└── Status: Running

Pod 3: frontend-app-654d9bcf94-sz86k
├── Node: fargate-ip-192-168-85-86.ec2.internal
├── IP: 192.168.85.86  
└── Status: Running
```

**Why Created:**
- Represents a production-like frontend application
- Tests LoadBalancer service integration
- Demonstrates horizontal scaling (3 replicas)

---

### 10. **Service: fargate-web-service (ClusterIP)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: fargate-web-service
  namespace: fargate-ns
spec:
  type: ClusterIP
  clusterIP: 10.100.143.20
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: fargate-web
```

**Network Details:**
- **Internal IP:** `10.100.143.20`
- **Port Mapping:** 80 → 80
- **Endpoints:** 2 pod IPs (load balanced)
- **Access:** Internal cluster communication only

**Why Created:**
- Provides stable internal endpoint for web application
- Enables service discovery within cluster
- Load balances traffic across 2 replicas

---

### 11. **Service: frontend-service (LoadBalancer)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: web-apps
spec:
  type: LoadBalancer
  loadBalancerIP: abea71e7872ce49e5a04c3b9c7f391dc-1050044846.us-east-1.elb.amazonaws.com
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30802
```

**Load Balancer Details:**
- **Type:** AWS Classic Load Balancer (ELB)
- **External DNS:** `abea71e7872ce49e5a04c3b9c7f391dc-1050044846.us-east-1.elb.amazonaws.com`
- **Health Check Status:** Unhealthy (Fargate + Classic ELB limitation)
- **Endpoints:** 3 pod IPs
- **Port:** 80:30802/TCP

**Why Created:**
- Attempt to provide external internet access
- Demonstrates LoadBalancer service type
- **Issue:** Classic ELB doesn't work with Fargate (needs ALB controller)

---

### 12. **Service: frontend-clusterip (ClusterIP)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-clusterip  
  namespace: web-apps
spec:
  type: ClusterIP
  clusterIP: 10.100.37.167
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: frontend
    tier: frontend
```

**Why Created:**
- Alternative internal access to frontend application
- Used for port-forwarding and kubectl proxy access
- Backup service when LoadBalancer has issues

---

## 🔧 **Service Dependencies & Communication Flow**

```
External Request Flow:
┌─────────────────┐    Port Forward    ┌─────────────────┐
│   Your Browser  │ ←─────────────────→ │   kubectl       │
│ localhost:9080  │                    │ port-forward    │
└─────────────────┘                    └─────────────────┘
                                                │
                                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster                              │
│                                                             │
│  ┌─────────────────┐    Routes to    ┌─────────────────┐   │
│  │frontend-clusterip│ ──────────────→ │  frontend-app   │   │
│  │  10.100.37.167  │                 │     pods        │   │
│  │                 │                 │   (3 replicas)  │   │
│  └─────────────────┘                 └─────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 💰 **Cost Breakdown by Service**

| Service | Type | Monthly Cost | Notes |
|---------|------|--------------|-------|
| EKS Control Plane | Fixed | $73.00 | Always running |
| Fargate Pods (6 pods) | Variable | $20-25 | 0.25 vCPU, 0.5GB each |
| Classic Load Balancer | Fixed | $18.00 | Even if not working |
| Data Transfer | Variable | $5-10 | Depends on usage |
| **Total** | | **~$116-126** | |

**Cost Optimization Notes:**
- Fargate scales to zero when no pods running
- No EC2 instance costs (would be ~$60/month for t3.medium)
- Can delete LoadBalancer to save $18/month if not needed

This comprehensive breakdown shows every service created, its purpose, configuration, and role in the overall architecture.
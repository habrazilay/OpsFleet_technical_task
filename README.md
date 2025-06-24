# EKS Cluster with Karpenter (Spot + Graviton Support) — Terraform POC

This project is a proof-of-concept for automating the deployment of an AWS EKS cluster using Terraform. It includes a setup for Karpenter as a cluster autoscaler with support for both x86 and arm64 (Graviton) architectures using Spot instances. It also contains a cloud architecture proposal for a fictional startup, *Innovate Inc.*, designed to be scalable, secure, and cloud-native.

---

## 📦 Project Structure

```
OpsFleet_technical_task/
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── dev.tfvars
│   │   ├── main.tf
│   │   ├── old.backend-dev.hcl.notinuse
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.1750763648.backup
│   │   ├── terraform.tfstate.backup
│   │   ├── tfplan
│   │   ├── tfplan.vpc
│   │   └── variables.tf
│   └── eks-providers.tf
├── karpenter-provisioners/
│   ├── nodeclass.yaml
│   ├── provisioner-arm64-spot.yaml
│   └── provisioner-x86-spot.yaml
├── lock-policy.json
├── Makefile
├── modules/
│   ├── eks/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── karpenter/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── vpc/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── README.md
└── terraform.tfstate.d/
    └── dev/

```

---

## 🚀 Getting Started

### Prerequisites

- Terraform >= 1.3
- AWS CLI with proper IAM permissions
- `kubectl`, `helm`, `eksctl`

### Deployment Steps

1. Initialize and deploy infrastructure:
   ```bash
   terraform init
   terraform apply
   ```

2. Configure `kubectl`:
   ```bash
   aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
   ```

3. Install Karpenter via Helm.

4. Apply the provided provisioners for both `amd64` and `arm64`.

---

## 🧪 Testing Workloads on Different Architectures

You can deploy workloads targeting specific architectures using nodeSelectors:

```yaml
# x86 workload
nodeSelector:
  kubernetes.io/arch: amd64

# Graviton workload
nodeSelector:
  kubernetes.io/arch: arm64
```

Karpenter will auto-provision Spot instances accordingly.

---

## 🏗️ Innovate Inc. Architecture (High-Level Overview)

We propose an architecture for Innovate Inc. using AWS as the preferred provider.

### 🔐 Cloud Environment Structure

- **3 AWS Accounts:**
  - `dev` – Development & testing
  - `staging` – QA & pre-production
  - `prod` – Production environment

Using AWS Organizations for centralized billing and control.

### 🌐 VPC Design

- Public/private subnet separation
- NAT Gateway for private workloads
- VPC Flow Logs and Network ACLs for enhanced security

### ☸️ Kubernetes (EKS)

- Deployed via Terraform
- Karpenter for dynamic autoscaling
- Two node groups: Spot x86 and Spot arm64
- ArgoCD for GitOps-based deployment

### 🐳 Containerization Strategy

- Dockerized Flask + React apps
- GitHub Actions for CI
- Amazon ECR for image storage
- CD via ArgoCD

### 🛢 PostgreSQL Database

- Use Amazon RDS (PostgreSQL)
- Multi-AZ for HA
- Automated backups + snapshots
- Disaster recovery via cross-region replication

---

## 🗺️ Architecture Diagram

![Innovate Inc. High-Level Architecture](./docs/innovate-architecture.png)

---

## 📄 License

MIT License


**Next step:** save the content above as `README.md`, commit (`git commit -m "docs: complete POC README"`), and push.  
Once the NodeClass + two NodePools YAMLs are in `karpenter/`, the repository fulfils every bullet in the technical task.


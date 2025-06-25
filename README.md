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

# OpsFleet – EKS + Karpenter reference environment
> Terraform 1.8 · AWS provider ≥5 · EKS module 20.x · Karpenter 0.37  
> Author: DAniel Schmidt

---

## 0.  Quick diagram

```text
┌────────────┐           ┌──────────┐
│  developer │──tf→ VPC ─┼─►  EKS   ├───►   core node‑group (tiny, on‑demand)
└────────────┘           └──────────┘                │
        ▲                                          Helm (IRSA)
        │                                              │
        │                                        Karpenter
        │                                              ▼
        │                                   Spot & on‑demand capacity
        │
        └── GitHub Actions / Atlantis (optional)
```

---

## 1.  Prerequisites

| item | version / notes |
|------|-----------------|
| Terraform CLI | **1.8.x**\* |
| AWS CLI       | ≥ 2.15 |
| `aws` profile | `opsfleet-dev` with the *candidates‑restricted* policy shown below **plus** the two additions noted in §1.1 |
| kubectl       | matches the EKS minor (v1.32) |
| helm          | ≥ 3.15 |

\*The provider lock‑files (`.terraform.lock.hcl`) are committed; a higher TF CLI works too.

### 1.1  Temporary IAM additions for the lab user

Add these two statements (or detach the managed policies) **before any `terraform apply`**:

```json
{
  "Effect": "Allow",
  "Action": "iam:CreateOpenIDConnectProvider",
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": "eks:AssociateAccessPolicy",
  "Resource": "*"
}
```

> The first is needed by the `terraform-aws-modules/eks` module when `enable_irsa = true`.  
> The second allows the one‑liner that maps your IAM user to `system:masters` via the new EKS “Access Entry” API.

Remove them afterwards if your security restrictions require.

---

## 2.  One‑time bootstrap

```bash
# clone, then…
make init           # terraform init + provider/version checks
aws sts get-caller-identity --profile opsfleet-dev  # sanity
```

---

## 3.  Recommended apply workflow (module‑by‑module)

> Trying to run **everything** in a single `terraform apply` often fails on fresh
> accounts because Karpenter needs the cluster and the OIDC provider *first*.

| step | command | rationale |
|------|---------|-----------|
| **3‑a** | `terraform -chdir=environments/dev apply -var-file=dev.tfvars -target=module.vpc` | carve the VPC & subnets; safe & idempotent |
| **3‑b** | `terraform … apply -target=module.eks` | builds the cluster + tiny `core` node‑group & core add‑ons |
| **3‑c** | **map yourself to `system:masters`**<br>```bash\naws eks associate-access-policy \\\n  --profile opsfleet-dev \\\n  --cluster-name opsfleet-eks-dev-us-east-1 \\\n  --principal-arn arn:aws:iam::851725384896:user/daniel_schmidt \\\n  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \\\n  --access-scope type=cluster\n``` | new (2024‑11) EKS *Access Entry* API – succeeds in seconds |
| **3‑d** | `aws eks update-kubeconfig --profile opsfleet-dev --name opsfleet-eks-dev-us-east-1`<br>`kubectl auth can-i '*' '*'` | verify we are cluster‑admin |
| **3‑e** | `terraform … apply -target=module.karpenter` | IRSA role ➜ namespace ➜ Helm release |
| **3‑f** | `kubectl -n karpenter rollout status deploy/karpenter`<br>`kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --tail=20` | ensure it has valid STS creds; if **AccessDenied** → double‑check the role trust JSON (below) |

Once all three modules are healthy you can drop the `-target` flags and run
`make plan` / `make apply` as usual.

---

## 4.  IRSA trust ‑ reference JSON

Every time Terraform runs it renders this into  
`aws_iam_role.karpenter.assume_role_policy`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.<REGION>.amazonaws.com/id/<OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<REGION>.amazonaws.com/id/<OIDC_ID>:sub": "system:serviceaccount:karpenter:karpenter"
        }
      }
    }
  ]
}
```

If Karpenter crashes with `WebIdentityErr` **after** this trust policy is in
place, the usual culprit is a race: delete the failing pods once and they will
restart with fresh tokens:

```bash
kubectl -n karpenter delete pod -l app.kubernetes.io/name=karpenter
```

---

## 5.  Makefile targets

| target | does |
|--------|------|
| `make init` | `terraform init` for `./environments/dev` |
| `make plan` | `terraform plan -var-file=dev.tfvars` |
| `make apply` | **assumes the three‑step bootstrap already done**; runs a full apply |
| `make destroy` | tears down the dev environment (VPC remains for speed) |

---

## 6.  Troubleshooting checklist

1. **Node‑group stuck** → Check subnets are private *and* have route to a NAT; verify that the AMI matches CPU arch (`t4g.medium` = ARM64).
2. **`Unsupported authentication mode update`** → never set `access_config.authentication_mode` manually; let the module manage it.
3. **Karpenter pending** → make sure at least one EC2 instance family in your provisioners is allowed by the AWS account’s service‑quotas and AZ‑availability.

---

## 7.  Cleaning up

```bash
make destroy               # modules
aws eks delete-cluster …   # if Terraform lost state
bash nuke-account.sh       # ☢  danger – removes **all** resources in the account
```

---

*(The remainder of the original README – design goals, module authors,
licence – stays unchanged below this line.)*

# Innovate Inc. – Cloud Architecture Design

## Overview

Innovate Inc. is a fast‑growing SaaS startup building a **Flask REST API**, **React SPA**, and **PostgreSQL** data tier. This design leverages the **existing VPC (10.0.0.0/16) created in Task #1** and follows AWS Well‑Architected, Kubernetes, and Terraform best practices to deliver a secure, scalable, and cost‑effective platform.

### High‑Level Diagram (Mermaid)

```mermaid
flowchart LR
  subgraph AWS Account – Innovate‑Prod
    direction TB
    VPC[Existing VPC 10.0.0.0/16]
    subgraph Public Subnets
      ALB[Application\nLoad Balancer]
      NAT[NAT Gateway]
    end
    subgraph Private Subnets
      EKS[EKS Cluster + Karpenter]
      RDS[RDS Aurora PG Serverless v2]
    end
    ALB -->|HTTPS 443| EKS
    React[CloudFront + S3 SPA] -->|HTTPS 443| ALB
    Users((Internet)) -->|HTTPS 443| React
    EKS -->|5432| RDS
    Logs[CloudWatch Logs]
    EKS --> Logs
  end
```

---

## 1. Cloud Environment Structure

| AWS Account              | Purpose                                       | Key Services                                                    |
| ------------------------ | --------------------------------------------- | --------------------------------------------------------------- |
| **Landing / Management** | Central billing, identity, and governance.    | IAM Identity Center, AWS Config, CloudTrail, GuardDuty, Budgets |
| **Shared Services**      | Cross‑environment tooling and networking hub. | ECR, SSM, VPC Sharing                                           |
| **Non‑Prod**             | Dev & Staging workloads.                      | EKS‑Dev, RDS‑Dev, KMS                                           |
| **Prod**                 | Production workloads (this doc).              | EKS‑Prod, RDS‑Prod                                              |

*Why*: Multi‑account strategy isolates blast‑radius, enforces least‑privilege, and simplifies cost allocation via AWS Organizations & SCPs.

---

## 2. Network Design

* **VPC** – Re‑use 10.0.0.0/16 VPC with 3 AZs and the following subnet layout:

  * *Public*: 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24 (ALB, NAT GW)
  * *Private*: 10.0.3.0/24 – 10.0.5.0/24 (EKS nodes, RDS)
* **Security Controls**

  * SGs restrict ALB → EKS (443) and EKS → RDS (5432).
  * Interface VPC Endpoints for S3, ECR, STS keep traffic private.
  * Network ACLs allow only ephemeral ports (stateless).
* **Internet Access**

  * Single NAT Gateway (cost‑optimised) in AZ‑A for outbound traffic.
  * SPA hosted on S3 behind CloudFront; API exposed via ALB with AWS WAF.

---

## 3. Compute Platform – Amazon EKS

* **Cluster**: One EKS cluster (v1.32) per environment; control‑plane logs (api, audit, authenticator) → CloudWatch.
* **Node Provisioning** using **Karpenter**:

  * Managed Node Group **core** (t4g.small ARM) for critical add‑ons.
  * Provisioner **spot‑arm64** – Graviton Spot; **spot‑amd64** – x86 Spot.
  * Consolidation & TTL = 300 s to downscale quickly.
* **Workload Isolation**: Namespaces + NetworkPolicies; IRSA for AWS access; PodSecurity Standards (restricted) enforced by OPA/Gatekeeper.
* **Autoscaling**: HPA/KEDA for pods; Karpenter for nodes.

---

## 4. Containerization & CI/CD

1. **GitHub Actions**

   * Build multi‑arch images with `docker buildx`.
   * Push to Amazon ECR with immutable tags.
   * Run unit tests + Snyk scans.
2. **Helm + Argo CD (GitOps)**

   * Chart‑releaser publishes Helm charts to GitHub Pages.
   * Argo CD syncs to EKS; Argo Rollouts enables blue/green deployments.

---

## 5. Database – Amazon Aurora PostgreSQL Serverless v2

| Aspect       | Design Choice                                          |
| ------------ | ------------------------------------------------------ |
| **Engine**   | Aurora PG Serverless v2 (11 or 15)                     |
| **Scaling**  | 0.5 – 64 ACUs automatic                                |
| **HA**       | Multi‑AZ writer + reader; fail‑over < 30 s             |
| **DR**       | Cross‑region reader in us‑west‑2                       |
| **Backups**  | PITR; snapshots retained 7 days; cross‑region copy     |
| **Security** | KMS‐encryption, TLS 1.2, Secrets Manager, SG 5432 only |

---

## 6. Security & Compliance

* IAM least‑privilege & SCP guard‑rails (deny `*:*` in Prod).
* Encryption everywhere (EBS, S3, RDS, Secrets, EKS configuration).
* GuardDuty + Security Hub + AWS WAF + Shield Advanced (optional).
* Vulnerability scanning (Trivy, Snyk) in CI; runtime scanning with Falco.

---

## 7. Observability

* **Logs**: Fluent‑bit → CloudWatch Logs → S3 (lifecycle to Glacier).
* **Metrics**: Prometheus + Grafana (Helm); Container Insights optional.
* **Tracing**: AWS Distro for OpenTelemetry → X‑Ray.

---

## 8. Cost Optimisation

* Single NAT GW + VPC Endpoints reduce data‑processing costs.
* Spot instances via Karpenter (≈70 % savings) + small On‑Demand core pool.
* Aurora Serverless scales to zero when idle.
* After baseline, purchase Compute Savings Plans.

---

## 9. Future Enhancements

* Add EKS Fargate profile for short‑lived jobs.
* Dedicated data‑warehouse account with Redshift RA3.
* Automate module publishing via Terraform Cloud.

---

### Change Log

| Date       | Version | Author         | Notes         |
| ---------- | ------- | -------------- | ------------- |
| 2025‑06‑25 | 0.1     | Daniel Schmidt | Initial draft |


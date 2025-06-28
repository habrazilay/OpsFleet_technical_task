# Innovate Inc. AWS Architecture Design Document

## 1. Executive Summary

Innovate Inc. will launch its Python/Flask REST API and React single-page application (SPA) on AWS using Amazon EKS (managed Kubernetes). The architecture is designed to be lean and cost-effective at launch (leveraging Fargate and serverless components) while providing scalability to millions of users through Spot/Graviton nodes, Multi-AZ RDS PostgreSQL, and optional cross-region failover. Security, automation, and cost-optimization are embedded from day one.

---

## 2. Account / Project Structure

| Account                          | Purpose                                     | Key Services                                        | Notes                                                        |
| -------------------------------- | ------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| **Management / Shared-Services** | Centralized security, billing, IAM, logging | IAM Identity Center, GuardDuty, AWS Config, S3 Logs | No workloads. Central log archive. Budget tracking.          |
| **Sandbox / Dev**                | Testing, feature development                | EKS-Dev, RDS-Dev (small), S3 Artifacts              | Budget limits, auto-shutdown for cost savings.               |
| **Production**                   | User-facing workloads & data                | EKS-Prod, RDS-Prod, CloudFront, KMS, WAF            | Strict SCPs, delegated GuardDuty admin, no public DB access. |

**Why three accounts?**
Follows AWS Well-Architected best practices for isolation, billing clarity, blast-radius reduction, and least-privilege access.

---

## 3. Networking Design

**VPC Layout:** One VPC per account:

* Dev: `10.10.0.0/16`
* Prod: `10.20.0.0/16`

Each VPC spans **3 Availability Zones**:

* **Public Subnet (/20)**: ALB, NAT Gateway (one per AZ)
* **Private-App Subnet (/20)**: EKS/Fargate ENIs
* **Private-Data Subnet (/24)**: RDS, ElastiCache (future)

**Security Features:**

* NAT Gateway enables egress without exposing internal resources
* Security Groups restrict access (e.g., ALB only allows HTTPS 443 to API)
* WAFv2 + CloudFront in front of ALB
* VPC Flow Logs stream to central log account (S3, 7-day retention)

---

## 4. Compute Platform – Amazon EKS

### 4.1 Cluster Layout

| Node Group                    | Type                  | Use-Case                         | Cost Profile                    |
| ----------------------------- | --------------------- | -------------------------------- | ------------------------------- |
| **Fargate Profile (default)** | Serverless            | Low initial traffic, system pods | Pay-per-pod, scale-to-zero      |
| **Managed NG – System**       | t4g.small (On-Demand) | kube-system, ALB Controller      | Always ≥1 per AZ                |
| **Karpenter – Spot arm64**    | Graviton (m7g, c7g)   | API & SPA pods                   | \~60–70% cheaper than On-Demand |
| **Karpenter – Spot x86**      | AMD (m7a, c7a)        | x86-only workloads               | Backup for incompatible images  |

* **Scaling:** Horizontal Pod Autoscaler (HPA) + Karpenter (sub-minute response)
* **Isolation:** Namespaces per stage (e.g., `prod`, `dev`, `ci-preview-*`)
* **IAM Roles for Service Accounts (IRSA):** ALB Controller, External-DNS, Cluster Autoscaler

### 4.2 Container Strategy

* **Image Build:** Multi-arch (linux/arm64, amd64) using Docker `buildx` in GitHub Actions
* **Container Registry:** Amazon ECR (with image scanning)
* **Deployment:** Helm charts version-controlled; Argo CD handles GitOps deployments

---

## 5. Database Layer – PostgreSQL

| Feature               | Details                                     |
| --------------------- | ------------------------------------------- |
| **Service**           | Amazon RDS PostgreSQL (Multi-AZ)            |
| **Backups**           | Daily snapshots (7–35 days) to S3 Glacier   |
| **High Availability** | Multi-AZ standby, automatic failover (<60s) |
| **Disaster Recovery** | Future: Cross-region replica (eu-west-1)    |
| **Encryption**        | AES-256 at rest via KMS, TLS in transit     |

---

## 6. CI/CD & Infrastructure as Code

* **Source Control:** GitHub
* **Workflows:**

  * Terraform (`/infra`): PR plan → Merge apply (assumes role via OIDC)
  * Docker Buildx matrix builds → Push to ECR
  * Helm deploys → Argo CD syncs to EKS
  * Rollback: `git revert` → Argo auto-sync; DB snapshots used for data restore

---

## 7. Observability & Security

| Area               | Tooling / Practice                                                |
| ------------------ | ----------------------------------------------------------------- |
| **Logs**           | Fluent Bit from EKS → Central S3; CloudWatch for Fargate logs     |
| **Metrics**        | Prometheus Operator, Grafana dashboards, Container Insights       |
| **Tracing**        | AWS X-Ray                                                         |
| **Secrets**        | AWS Secrets Manager with CSI driver, rotated every 30 days        |
| **Security Tools** | GuardDuty, IAM Access Analyzer, SSM Session Manager (no SSH), WAF |

---

## 8. Cost-Optimisation Strategies

| Lever                                   | Estimated Saving  | Notes                                      |
| --------------------------------------- | ----------------- | ------------------------------------------ |
| **Graviton Spot for stateless pods**    | 60–70%            | Graviton processors + spot market pricing  |
| **Karpenter rightsizing/consolidation** | 10–20%            | Packs pods optimally; removes idle nodes   |
| **Fargate scale-to-zero**               | 100% when idle    | Pay only for running pods                  |
| **S3 Intelligent-Tiering**              | \~30%             | Automatically moves logs to colder storage |
| **RDS storage autoscaling**             | Pay-for-GB used   | Avoids overprovisioning unused storage     |
| **Dev environment auto-shutdown**       | \~50% off-hours   | Stops non-prod clusters after work hours   |
| **Budgets & Anomaly Detection**         | Early cost alerts | Catch spikes before they snowball          |

---

## 📈 Summary

This architecture allows Innovate Inc. to:

* Start lean with Fargate and pay-per-use compute
* Scale efficiently using Spot and Graviton nodes
* Follow modern GitOps and CI/CD automation
* Maintain strong security and observability
* Optimize cost with automated tooling and guardrails

It aligns with the AWS Well-Architected Framework and provides a solid, scalable foundation for growth.

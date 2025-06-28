# 📊 Cloud Provider Cost Comparison (June 2025)

| **Component**             | **AWS**                             | **GCP**                             | **Azure**                          |
| ------------------------- | ----------------------------------- | ----------------------------------- | ---------------------------------- |
| **Managed Kubernetes**    | EKS Fargate + Spot (\~\$70–\$150)   | GKE Autopilot + Spot (\~\$60–\$140) | AKS + B-series/Spot (\~\$75–\$160) |
| **PostgreSQL (Prod)**     | RDS Multi-AZ (\~\$130)              | Cloud SQL HA (\~\$145)              | Azure Flexible Server HA (\~\$135) |
| **Storage (Logs/Static)** | S3 Standard + Glacier (\~\$20–\$30) | Cloud Storage + Nearline (\~\$25)   | Azure Blob + Archive (\~\$28)      |
| **CI/CD Runtime**         | GitHub Actions (free/low)           | Cloud Build + GitHub (\~\$0–\$10)   | GitHub + Azure Pipelines (\~\$10)  |
| **Load Balancer + WAF**   | ALB + WAF (\~\$40)                  | HTTP LB + Cloud Armor (\~\$35)      | App Gateway + WAF (\~\$50)         |
| **Container Registry**    | ECR (\~\$1–\$5)                     | Artifact Registry (\~\$1–\$5)       | ACR (\~\$1–\$5)                    |
| **Monitoring + Logs**     | CloudWatch + Grafana (\~\$25)       | Cloud Monitoring (\~\$20–\$25)      | Azure Monitor (\~\$25–\$30)        |
| **IAM/Security Services** | IAM, GuardDuty, Secrets (\~\$10)    | IAM, Secret Manager (\~\$8)         | RBAC, Defender, Key Vault (\~\$12) |
| **Est. Total (Lean MVP)** | **\$300–\$400**                     | **\$290–\$390**                     | **\$310–\$420**                    |
| **Est. Total (Scaled ↑)** | **\$900–\$1,200**                   | **\$850–\$1,150**                   | **\$950–\$1,250**                  |

---

## 🔍 Observations

| **Area**                | **AWS Strength**                      | **GCP Strength**                    | **Azure Strength**                    |
| ----------------------- | ------------------------------------- | ----------------------------------- | ------------------------------------- |
| **Kubernetes**          | Graviton + Spot + Fargate flexibility | GKE Autopilot simplicity            | Deep AKS integration with Azure       |
| **Cost Predictability** | Cost Anomaly Detection, Budgets       | Quotas + Predictable Autopilot fees | Azure Reservations help predict costs |
| **CI/CD**               | GitHub-native                         | Tight GitHub + GKE integration      | GitHub + Azure DevOps Pipelines       |
| **Database**            | Best-in-class RDS management          | Easy scaling, slower failover       | Competitive HA, newer API surface     |
| **Global Presence**     | Strong in North America + EU          | Superior latency in Asia-Pacific    | Very strong enterprise compliance     |

---

## 💡 Cost-Saving Summary

| **Lever**                    | **AWS**       | **GCP**             | **Azure**                 |
| ---------------------------- | ------------- | ------------------- | ------------------------- |
| **Spot + Graviton**          | ✓ (up to 70%) | ✓ (via GKE Spot)    | ✓ (Spot VMs)              |
| **Fargate / Serverless**     | ✓             | ✓ (Autopilot model) | Partial (ACI integration) |
| **Autoscaling DB & Storage** | ✓             | ✓                   | ✓                         |
| **Tiered Object Storage**    | ✓             | ✓                   | ✓                         |
| **Budget & Alerts**          | ✓             | ✓                   | ✓                         |

---

## 🎝️ Final Recommendation

For **early-stage scalability** with a balance of **cost, flexibility, and ecosystem maturity**, **AWS remains the strongest option** for Innovate Inc., particularly due to:

* Mature **multi-arch and Spot compute** via **Karpenter + Graviton**
* Greater control and isolation via **EKS**, IRSA, and Namespaces
* Extensive cloud-native automation tools (Terraform, Argo CD, Budgets)
* Competitive total cost with better long-term scalability posture

> See also: [Cloud Cost Bar Chart](https://www.mermaidchart.com/app/mermaid-chart-save/2025-06-28/7dd9fcb3-d36e-4f72-8199-dc6f12c337ad)


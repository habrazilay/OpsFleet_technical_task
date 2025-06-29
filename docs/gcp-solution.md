### Cloud Infrastructure Design for Innovate Inc.  
**Solution Provider**: Google Cloud Platform (GCP)  
**Justification**: GCP offers simplified Kubernetes management (GKE), cost-effective scaling, integrated security, and startup-friendly pricing. It outperforms AWS for managed Kubernetes, PostgreSQL, and CI/CD integration for Python/React stacks.

---

### 1. Cloud Environment Structure  
**GCP Projects** (4 projects total):  
- **Production**: Hosts live user-facing apps.  
- **Staging**: Mirrors production for testing.  
- **Development**: Sandbox for feature experimentation.  
- **Shared-Services**: Centralized logging, CI/CD, and container registry.  

**Justification**:  
- **Isolation**: Prevent cross-environment accidents (e.g., staging changes affecting production).  
- **Billing**: Track costs per environment; set budgets per project.  
- **Security**: Apply least-privilege IAM roles per project.  

---

### 2. Network Design  
**VPC Architecture** (per environment):  
- **Public Subnet**: HTTP(S) load balancers (global access).  
- **Private Subnet 1**: GKE nodes (no public IPs).  
- **Private Subnet 2**: Cloud SQL (isolated DB layer).  
- **Region**: `us-central1` (low latency, cost-effective).  

**Security**:  
- **Firewall Rules**:  
  - Allow HTTP/HTTPS only from Google Cloud Load Balancer to GKE.  
  - Block all public access to DBs; allow only GKE backend pods.  
- **Cloud Armor**: DDoS protection and WAF rules for Load Balancer.  
- **Private Service Connect**: Securely connect GKE to Cloud SQL.  
- **Cloud NAT**: Outbound internet access for private GKE nodes.  

---

### 3. Compute Platform: GKE  
**Cluster Design**:  
- **Regional Cluster**: Spread across 3 zones for HA.  
- **Autopilot Mode**: Fully managed nodes (no node maintenance).  

**Node Groups & Scaling**:  
- **Frontend Pool**: Preemptible VMs (cost-efficient for stateless React SPA).  
- **Backend Pool**: Standard VMs (stateful Flask API).  
- **Autoscaling**:  
  - **Horizontal Pod Autoscaler (HPA)**: Scale pods based on CPU/memory.  
  - **Cluster Autoscaler**: Add nodes during traffic spikes.  

**Containerization Strategy**:  
- **Image Building**:  
  - **Backend**: Python/Flask → Dockerfile w/ Gunicorn.  
  - **Frontend**: React → Multi-stage Dockerfile (nginx base).  
- **Registry**: **Artifact Registry** (private repo; integrated with GKE).  
- **Deployment**: GitOps using **Cloud Build** (CI/CD):  
  - Push to `main` branch → Build image → Test in Staging → Manual approval → Production rollout.  

---

### 4. Database: PostgreSQL  
**Service**: **Cloud SQL** (managed PostgreSQL).  

**Justification**:  
- Automated backups, patching, and HA.  
- Integrates with GKE via private IP.  
- Compliant (HIPAA, SOC2) for sensitive data.  

**High Availability & DR**:  
- **HA Mode**: Multi-zone instance (auto-failover).  
- **Backups**: Daily automated backups + transaction logs (PITR).  
- **Disaster Recovery**:  
  - Clone DB to standby cluster in `us-east1` region.  
  - Test failover quarterly.  

---

### High-Level Diagram (HDL)  
```mermaid
graph TD
  A[Internet] --> B[Google Cloud HTTP/S Load Balancer]
  B --> C[Frontend: React SPA<br>(GKE Autopilot)]
  B --> D[Backend: Flask API<br>(GKE Autopilot)]
  D --> E[Cloud SQL PostgreSQL<br>(Private IP)]
  F[Cloud Build CI/CD] -->|Deploys| C
  F -->|Deploys| D
  G[Artifact Registry] -->|Stores Images| F
  H[Cloud Logging/Monitoring] -->|Logs & Metrics| ALL
  style B stroke:#EA4335,stroke-width:2px
  style E stroke:#34A853,stroke-width:2px
```

---

### Cost Optimization  
- **Preemptible VMs**: For frontend node pool (save 80%).  
- **Commitments**: Sustained-use discounts for backend VMs.  
- **Autopilot**: Pay per pod (no node overprovisioning).  

### Security Highlights  
- **Secret Management**: **Secret Manager** for DB credentials.  
- **IAM**: Service accounts for GKE ↔ Cloud SQL least privilege.  
- **VPC Service Controls**: Isolate production resources.  

### Deliverables  
- **GitHub Repo**: Includes:  
  - `README.md` (this document).  
  - `architecture_diagram.png` (HDL visual).  
  - `/terraform` (infrastructure-as-code setup).  

---  
**Next Steps**:  
1. Set up GCP projects via Terraform.  
2. Configure Cloud Build pipelines for React/Flask.  
3. Enable centralized logging via Cloud Operations.  

[GitHub Repository Link](https://github.com/innovate-inc-cloud/architecture)
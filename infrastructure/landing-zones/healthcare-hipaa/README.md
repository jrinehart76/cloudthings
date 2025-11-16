# Healthcare HIPAA Landing Zone

A production-ready Azure landing zone designed for healthcare organizations requiring HIPAA compliance. Based on real-world implementations supporting 5,000+ users in regulated healthcare environments.

## Overview

This landing zone implements all technical safeguards required by HIPAA, including:
- Access controls (§164.312(a)(1))
- Audit controls (§164.312(b))
- Integrity controls (§164.312(c)(1))
- Transmission security (§164.312(e)(1))
- Encryption (§164.312(a)(2)(iv) and §164.312(e)(2)(ii))

## Architecture

```
Healthcare HIPAA Landing Zone
│
├── Management Groups
│   ├── Platform (Shared Services)
│   │   ├── Management (Monitoring, Backup)
│   │   ├── Connectivity (Hub Network)
│   │   └── Identity (Azure AD, Key Vault)
│   │
│   └── Landing Zones (Workloads)
│       ├── Production (PHI Data)
│       ├── Non-Production (De-identified Data)
│       └── Sandbox (Development)
│
├── Network Topology (Hub-Spoke)
│   ├── Hub VNet (10.0.0.0/16)
│   │   ├── Azure Firewall
│   │   ├── VPN Gateway
│   │   └── Bastion Host
│   │
│   ├── Production Spoke (10.1.0.0/16)
│   │   ├── Application Tier
│   │   ├── Data Tier (Encrypted)
│   │   └── Management Tier
│   │
│   └── Non-Production Spoke (10.2.0.0/16)
│       ├── Development
│       └── Testing
│
├── Security Controls
│   ├── Azure Policy (HIPAA Compliance)
│   ├── Security Center (Standard Tier)
│   ├── Key Vault (Secrets, Keys, Certificates)
│   ├── Private Endpoints (All PaaS)
│   └── DDoS Protection (Standard)
│
├── Identity & Access
│   ├── Azure AD Premium P2
│   ├── Privileged Identity Management
│   ├── Conditional Access
│   ├── MFA Required
│   └── Just-in-Time Access
│
├── Monitoring & Compliance
│   ├── Log Analytics (365-day retention)
│   ├── Azure Sentinel (SIEM)
│   ├── Compliance Dashboard
│   ├── Audit Logging (All Resources)
│   └── Alert Rules (Security Events)
│
└── Data Protection
    ├── Encryption at Rest (All Storage)
    ├── Encryption in Transit (TLS 1.2+)
    ├── Azure Backup (Daily)
    ├── Geo-Redundant Storage
    └── Data Classification Tags
```

## HIPAA Compliance Mapping

### Administrative Safeguards
| Requirement | Implementation |
|-------------|----------------|
| Security Management Process | Azure Policy, Security Center |
| Workforce Security | Azure AD, RBAC, PIM |
| Information Access Management | Conditional Access, JIT |
| Security Awareness Training | Documentation, Runbooks |
| Security Incident Procedures | Azure Sentinel, Playbooks |

### Physical Safeguards
| Requirement | Implementation |
|-------------|----------------|
| Facility Access Controls | Azure Data Centers (SOC 2, ISO 27001) |
| Workstation Security | Bastion Host, No Direct Access |
| Device and Media Controls | Managed Disks, Encryption |

### Technical Safeguards
| Requirement | Implementation |
|-------------|----------------|
| Access Control | Azure AD, RBAC, PIM, MFA |
| Audit Controls | Log Analytics, 365-day retention |
| Integrity | File Integrity Monitoring |
| Transmission Security | TLS 1.2+, Private Endpoints |
| Encryption | AES-256 at rest, TLS in transit |

## Deployment

### Prerequisites
- Azure subscription with Owner access
- Azure AD Premium P2 licenses
- Terraform 1.0+ or Azure CLI
- Service principal with appropriate permissions

### Step 1: Configure Parameters

Edit `parameters.json`:
```json
{
  "organizationName": "contoso-health",
  "primaryRegion": "eastus",
  "secondaryRegion": "westus",
  "logRetentionDays": 365,
  "adminEmail": "security@contoso.com",
  "costCenter": "HC-IT-001"
}
```

### Step 2: Deploy Foundation

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Deploy (takes ~2 hours)
terraform apply tfplan
```

### Step 3: Configure Azure AD

```bash
# Enable Azure AD Premium features
./scripts/configure-azure-ad.sh

# Set up Conditional Access policies
./scripts/configure-conditional-access.sh

# Configure PIM
./scripts/configure-pim.sh
```

### Step 4: Enable Security Center

```bash
# Enable Standard tier
az security pricing create \
  --name VirtualMachines \
  --tier Standard

# Configure security contacts
az security contact create \
  --email security@contoso.com \
  --phone "555-0100" \
  --alert-notifications On \
  --alerts-admins On
```

### Step 5: Deploy Sentinel

```bash
# Deploy Sentinel workspace
./scripts/deploy-sentinel.sh

# Enable data connectors
./scripts/configure-sentinel-connectors.sh

# Deploy analytics rules
./scripts/deploy-sentinel-rules.sh
```

### Step 6: Validation

```bash
# Run compliance check
./scripts/validate-compliance.sh

# Test network connectivity
./scripts/test-network.sh

# Verify encryption
./scripts/verify-encryption.sh

# Check audit logging
./scripts/verify-logging.sh
```

## Security Features

### Encryption
- **At Rest:** AES-256 encryption for all storage
- **In Transit:** TLS 1.2+ for all connections
- **Key Management:** Azure Key Vault with HSM backing
- **Certificate Management:** Automated rotation

### Network Security
- **Segmentation:** Hub-spoke topology with NSGs
- **Firewall:** Azure Firewall with threat intelligence
- **Private Connectivity:** Private endpoints for all PaaS
- **DDoS Protection:** Standard tier enabled
- **Bastion:** Secure RDP/SSH without public IPs

### Identity Protection
- **MFA:** Required for all users
- **Conditional Access:** Risk-based policies
- **PIM:** Just-in-time privileged access
- **Identity Protection:** Risk detection and remediation

### Monitoring
- **Log Retention:** 365 days minimum
- **SIEM:** Azure Sentinel with analytics rules
- **Alerts:** Security events trigger automated response
- **Compliance:** Continuous compliance monitoring

## Cost Estimate

Monthly costs for typical healthcare deployment (approximate):

| Component | Monthly Cost |
|-----------|--------------|
| Compute (VMs) | $2,000 - $5,000 |
| Networking | $500 - $1,000 |
| Storage | $500 - $1,500 |
| Security Center | $300 - $600 |
| Azure Sentinel | $500 - $2,000 |
| Azure AD Premium P2 | $9/user |
| Backup | $200 - $500 |
| **Total** | **$4,000 - $10,600** |

*Costs vary based on scale and usage patterns*

## Maintenance

### Daily
- Review security alerts
- Monitor backup status
- Check compliance dashboard

### Weekly
- Review access logs
- Validate policy compliance
- Update threat intelligence

### Monthly
- Security assessment
- Cost optimization review
- Compliance reporting
- Certificate expiration check

### Quarterly
- Disaster recovery test
- Security training
- Policy review and updates
- Vendor risk assessment

## Compliance Reporting

### Built-in Reports
- HIPAA Compliance Dashboard
- Security Posture Score
- Audit Log Summary
- Access Review Report
- Encryption Status Report

### Custom Reports
```bash
# Generate compliance report
./scripts/generate-compliance-report.sh --format pdf

# Export audit logs
./scripts/export-audit-logs.sh --days 90

# Security assessment
./scripts/security-assessment.sh
```

## Disaster Recovery

### RPO/RTO Targets
- **Production:** RPO 1 hour, RTO 4 hours
- **Non-Production:** RPO 24 hours, RTO 8 hours

### Backup Strategy
- Daily VM backups (retained 30 days)
- Database backups every 6 hours
- Geo-redundant storage
- Automated testing monthly

### Failover Process
1. Declare disaster
2. Activate DR team
3. Failover to secondary region
4. Validate services
5. Communicate status
6. Document incident

## Troubleshooting

### Common Issues

**Issue:** Policy compliance showing non-compliant  
**Solution:** Run remediation task or update resources to meet policy

**Issue:** Private endpoint connectivity fails  
**Solution:** Verify DNS configuration and NSG rules

**Issue:** Sentinel alerts not triggering  
**Solution:** Check data connector status and analytics rule configuration

**Issue:** Backup failures  
**Solution:** Verify Recovery Services Vault permissions and network connectivity

## Support

For issues or questions:
1. Review troubleshooting guide
2. Check Azure Service Health
3. Consult HIPAA compliance documentation
4. Contact Azure support (include compliance requirements)

## Related Resources

- [HIPAA Compliance in Azure](https://docs.microsoft.com/azure/compliance/offerings/offering-hipaa-us)
- [Azure Security Benchmark](https://docs.microsoft.com/security/benchmark/azure/)
- [Healthcare Architecture](https://docs.microsoft.com/azure/architecture/industries/healthcare)
- [Governance Policies](../../arm-templates/policies/)

---

*This landing zone represents real-world patterns from healthcare environments supporting 5,000+ users with HIPAA compliance requirements.*

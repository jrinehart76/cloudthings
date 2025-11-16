# Azure Landing Zone Templates

Pre-configured Azure landing zones with governance built in from the start. These templates represent patterns proven across 100+ organizations in healthcare, energy, and enterprise sectors.

## Philosophy

> "Landing zones are not optional infrastructure. They're base camps along the Everest ascent. Each one is crucial for preparing you for the next stage." - [From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/)

Landing zones are pre-configured environments designed to host workloads with the five governance disciplines built in:
1. Cost Management
2. Security Baseline
3. Identity Baseline
4. Resource Consistency
5. Deployment Acceleration

## Available Landing Zones

### 🏥 Healthcare HIPAA
**Use Case:** Healthcare organizations requiring HIPAA compliance

**Features:**
- HIPAA-compliant security controls
- Audit logging for all resources
- Encryption at rest and in transit
- Network isolation and segmentation
- PHI data protection policies
- Compliance reporting dashboards

**Proven Scale:** 5,000+ users in regulated healthcare environments

**Deployment Time:** 2-3 hours

**Path:** `healthcare-hipaa/`

---

### 🏢 Enterprise Standard
**Use Case:** Large enterprises with complex governance requirements

**Features:**
- Multi-region support
- Hub-spoke network topology
- Centralized identity management
- Cost allocation by business unit
- Comprehensive monitoring
- Disaster recovery built-in

**Proven Scale:** 100+ organizations across multiple industries

**Deployment Time:** 3-4 hours

**Path:** `enterprise-standard/`

---

### 🏪 Small-Medium Business
**Use Case:** SMBs needing governance without complexity

**Features:**
- Simplified architecture
- Cost-optimized resources
- Essential security controls
- Single-region deployment
- Quick time-to-value
- Growth-ready design

**Proven Scale:** Dozens of SMB deployments

**Deployment Time:** 1-2 hours

**Path:** `small-medium-business/`

## Landing Zone Components

Each landing zone includes:

### 1. Management Group Structure
```
Root Management Group
├── Platform
│   ├── Management
│   ├── Connectivity
│   └── Identity
└── Landing Zones
    ├── Production
    ├── Non-Production
    └── Sandbox
```

### 2. Network Topology
- Hub-spoke or single VNet (depending on scale)
- Network Security Groups with baseline rules
- Azure Firewall or Network Virtual Appliances
- Private endpoints for PaaS services
- DDoS protection

### 3. Identity & Access
- Azure AD integration
- Privileged Identity Management
- Conditional Access policies
- Service principals with least privilege
- RBAC role assignments

### 4. Security Controls
- Azure Policy assignments
- Security Center configuration
- Key Vault for secrets
- Diagnostic settings enabled
- Threat detection active

### 5. Monitoring & Logging
- Log Analytics workspace
- Application Insights
- Azure Monitor alerts
- Diagnostic settings
- Workbooks for visualization

### 6. Cost Management
- Budgets and alerts
- Required tagging policies
- Resource group structure
- Cost allocation tags
- Reserved instance recommendations

## Deployment Process

### Prerequisites
- Azure subscription with Owner access
- Azure CLI or PowerShell installed
- Terraform or Bicep (depending on template)
- Service principal for automation

### Phase 1: Foundation (Week 1)
1. Deploy management group structure
2. Configure identity baseline
3. Set up networking
4. Enable monitoring

### Phase 2: Security (Week 2)
1. Deploy security policies
2. Configure Key Vault
3. Enable Security Center
4. Set up diagnostic logging

### Phase 3: Workload Readiness (Week 3)
1. Create landing zone subscriptions
2. Deploy network connectivity
3. Configure RBAC
4. Test deployment pipeline

### Phase 4: Validation (Week 4)
1. Run compliance checks
2. Test disaster recovery
3. Validate monitoring
4. Document as-built

## Customization Guide

### Naming Conventions
Update `naming-config.json` with your standards:
```json
{
  "resourceGroup": "rg-{workload}-{environment}-{region}",
  "virtualMachine": "vm-{workload}-{environment}-{instance}",
  "storageAccount": "st{workload}{environment}{random}"
}
```

### Tagging Strategy
Modify `tagging-policy.json`:
```json
{
  "requiredTags": [
    "CostCenter",
    "Environment",
    "Owner",
    "Application",
    "DataClassification"
  ]
}
```

### Network Addressing
Update `network-config.json`:
```json
{
  "hubVNet": "10.0.0.0/16",
  "productionSpoke": "10.1.0.0/16",
  "nonProductionSpoke": "10.2.0.0/16"
}
```

## Real-World Lessons

### What Works
✅ **Deploy governance before workloads** - Retrofitting costs 10x more  
✅ **Start with audit mode** - Understand impact before enforcing  
✅ **Automate everything** - Manual processes don't scale  
✅ **Document decisions** - Future you will thank present you  
✅ **Test in non-prod first** - Catch issues early  

### What Doesn't Work
❌ **Skipping cost controls** - Results in 200-400% overspend  
❌ **Treating security as "phase two"** - Creates vulnerabilities  
❌ **Granting broad permissions** - Temporary becomes permanent  
❌ **Manual deployments** - Creates configuration drift  
❌ **Inconsistent naming** - Makes everything harder  

## Success Metrics

Track these KPIs after deployment:

### Cost Management
- Spending within 5% of budget
- 95%+ resources properly tagged
- Zero orphaned resources

### Security Baseline
- 100% policy compliance
- Zero critical vulnerabilities
- All resources encrypted

### Identity Baseline
- Zero standing privileged access
- 100% MFA adoption
- Least privilege enforced

### Resource Consistency
- 95%+ naming compliance
- Consistent resource organization
- Automated deployments

### Deployment Acceleration
- 90%+ deployments via IaC
- <30 minute provisioning time
- Zero manual configuration

## Support & Troubleshooting

### Common Issues

**Issue:** Policy assignment fails  
**Solution:** Check management group hierarchy and permissions

**Issue:** Network connectivity problems  
**Solution:** Verify NSG rules and route tables

**Issue:** Cost alerts not triggering  
**Solution:** Confirm budget configuration and action groups

**Issue:** Compliance showing non-compliant  
**Solution:** Run remediation task or update resources

### Getting Help

1. Review deployment logs
2. Check Azure Activity Log
3. Validate prerequisites
4. Consult troubleshooting guide
5. Open GitHub issue with details

## Related Resources

- [From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/) - Governance fundamentals
- [Azure Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Landing Zone Accelerator](https://github.com/Azure/Enterprise-Scale)
- [Governance Policies](../arm-templates/policies/)
- [Log Analytics Queries](../log-analytics/)

## Contributing

Improvements welcome! Please:
1. Test thoroughly in non-production
2. Document changes clearly
3. Follow existing patterns
4. Update this README

---

*"You can't summit Everest by skipping base camps. You can't build enterprise cloud infrastructure by skipping governance."*

## Quick Start Commands

### Deploy Healthcare HIPAA Landing Zone
```bash
cd healthcare-hipaa
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy Enterprise Standard Landing Zone
```bash
cd enterprise-standard
az deployment mg create \
  --management-group-id "mg-root" \
  --location "eastus" \
  --template-file main.bicep \
  --parameters @parameters.json
```

### Deploy SMB Landing Zone
```bash
cd small-medium-business
./deploy.sh --environment prod --region eastus
```

# Azure Governance Policies

This directory contains Azure Policy definitions aligned with the five governance disciplines from the [Azure Cloud Adoption Framework](https://www.technicalanxiety.com/basecamp-summit/).

## The Five Governance Disciplines

### 1. Cost Management
Policies to control and optimize spending through budgets, monitoring, and cost allocation strategies.

**Policies:**
- `audit-resources-without-tags.json` - Ensures all resources have required tags for cost allocation
- `enforce-shutdown-schedule.json` - Enforces VM shutdown schedules to reduce costs
- `enforce-hybrid-use-benefit.json` - Ensures proper licensing to optimize costs

**Why it matters:** Cloud costs escalate immediately without guardrails. Organizations consistently overspend by 200-400% in their first quarter without proper cost governance.

### 2. Security Baseline
Security policies and controls including firewalls, network security groups, encryption, and threat detection.

**Policies:**
- `enforce-storage-account-firewall.json` - Ensures storage accounts have firewall rules
- `enforce-storage-account-endpoints.json` - Enforces service endpoints for secure connectivity
- `enforce-antimalware-extension.json` - Ensures VMs have antimalware protection
- `enforce-no-public-ips.json` - Prevents unauthorized public IP assignments
- `enforce-no-classic-resources.json` - Blocks legacy resources with weaker security

**Why it matters:** Security retrofits cost 10x more than building it correctly from the start. Establishing security after deployment is like installing airbags after the crash.

### 3. Identity Baseline
Managing identities and access through RBAC, MFA, and Privileged Identity Management.

**Policies:**
- Network isolation policies ensure proper segmentation
- Service endpoint policies enforce secure identity flows

**Why it matters:** Improper access control creates immediate risk. Over-privileged accounts are security incidents waiting to happen.

### 4. Resource Consistency
Uniform organization through naming conventions, tagging strategies, and structured management groups.

**Policies:**
- `audit-resources-without-tags.json` - Enforces consistent tagging
- `enforce-nic-to-subnet.json` - Ensures consistent network architecture

**Why it matters:** Inconsistent resource organization makes everything harder. The "we'll organize things later" approach never works.

### 5. Deployment Acceleration
Automating and standardizing deployments through Infrastructure as Code and CI/CD pipelines.

**Policies:**
- Diagnostic settings policies (`enforce-log-analytics/`, `enforce-event-hub/`) - Enable automated monitoring
- Policy initiatives that can be deployed via IaC

**Why it matters:** Manual deployments are slow, error-prone, and inconsistent. Proper governance through automation actually accelerates delivery.

## Policy Organization

```
policies/
├── README.md                                    # This file
├── governance-initiative.json                   # Complete governance policy set
├── cost-management/                             # Cost control policies
├── security-baseline/                           # Security policies
├── identity-baseline/                           # Identity and access policies
├── resource-consistency/                        # Organization policies
├── deployment-acceleration/                     # Automation policies
├── enforce-log-analytics/                       # Diagnostic settings for Log Analytics
└── enforce-event-hub/                           # Diagnostic settings for Event Hub
```

## Deployment Approach

### Phase 1: Foundation (Base Camp)
1. Deploy management group structure
2. Implement tagging policies (audit mode)
3. Enable diagnostic settings
4. Establish cost budgets and alerts

### Phase 2: Security Hardening
1. Enable security baseline policies
2. Implement network isolation
3. Configure identity controls
4. Enable threat detection

### Phase 3: Operational Excellence
1. Enforce resource consistency
2. Automate deployments
3. Implement monitoring and alerting
4. Enable continuous compliance

## Key Principles

**Start with governance, not workloads:** Implement policies before migrating applications. Retrofitting governance costs exponentially more.

**Audit before enforce:** Begin policies in audit mode to understand impact, then transition to enforcement.

**Automate everything:** Manual governance doesn't scale. Use Infrastructure as Code for all policy deployments.

**Measure and iterate:** Track policy compliance, cost trends, and security posture. Adjust policies based on data.

## Common Mistakes to Avoid

1. **Skipping cost controls** - Results in 200-400% overspend in first quarter
2. **Treating security as "phase two"** - Creates vulnerabilities that cost 10x more to fix
3. **Granting broad permissions temporarily** - Temporary always becomes permanent
4. **Manual deployments** - Creates configuration drift and operational chaos
5. **Inconsistent tagging** - Makes cost allocation and resource management impossible

## Related Resources

- [From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/) - Why cloud migrations fail without proper governance
- [Azure Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)

---

*"You can't summit Everest by skipping base camps. You can't build enterprise cloud infrastructure by skipping governance."*

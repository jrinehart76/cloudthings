# Azure Cloud Things

> Production-ready Azure governance, operations, and infrastructure templates from 20+ years of real-world experience.

[![Blog](https://img.shields.io/badge/Blog-Technical%20Anxiety-blue)](https://technicalanxiety.com)
[![Twitter](https://img.shields.io/twitter/follow/anxiouslytech?style=social)](https://twitter.com/anxiouslytech)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Jason%20Rinehart-blue)](https://linkedin.com/in/rinehart76)

## What is This?

This repository connects blog articles from [Technical Anxiety](https://technicalanxiety.com) to their practical implementations. Each article explains the "why" and "what" - this repository provides the "how" with actual code, queries, and templates you can use immediately.

> "If one person solves a problem faster because I documented what I learned, then this effort matters." - Jason Rinehart

## What's Inside

### 🏗️ Infrastructure Templates
- **427 ARM Templates** across 36 Azure resource types
- **3 Landing Zones** (Healthcare HIPAA, Enterprise, SMB)
- **Governance Policies** implementing the five disciplines
- All modernized to current API versions

### 📊 Log Analytics Queries
- **Cost Optimization** - Find unused resources, right-size VMs, identify waste
- **Security Monitoring** - Detect failed logins, brute force attacks
- **Operational Health** - VM performance, backup status, compliance

### 🤖 Automation Runbooks
- **Cost Management** - Auto-shutdown dev resources ($2-5k/month savings)
- **Security** - Automated key rotation, public IP auditing
- **Compliance** - Tag enforcement (95%+ compliance target)
- **Operations** - VM health checks, proactive monitoring

### 📚 Documentation
- Blog-to-code mapping
- Deployment guides
- Architecture patterns
- Real-world impact metrics

## Quick Start

### Cost Optimization Example
```bash
# Find unused resources costing you money
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query @infrastructure/log-analytics/cost-optimization/unused-resources.kql
```

### Deploy Governance Policies
```bash
# Deploy the five governance disciplines
az policy set-definition create \
  --name "governance-initiative" \
  --definitions @infrastructure/arm-templates/policies/governance-initiative.json \
  --management-group <mg-name>
```

### Deploy a Landing Zone
```bash
# Healthcare HIPAA-compliant landing zone
az deployment sub create \
  --location eastus \
  --template-file infrastructure/landing-zones/healthcare-hipaa/main.bicep
```

## Repository Structure

```
├── infrastructure/
│   ├── arm-templates/          # 427 ARM templates
│   │   ├── resources/          # By Azure resource type
│   │   ├── policies/           # Governance policies
│   │   ├── alertmanager/       # Alert configurations
│   │   └── dashboardmanager/   # Dashboard templates
│   ├── automation/             # PowerShell runbooks
│   ├── log-analytics/          # KQL queries
│   └── landing-zones/          # Reference architectures
├── scripts/                    # Utility scripts
├── archive/                    # Deprecated services (reference only)
└── docs/                       # Additional documentation
```

## Use Cases

### "I need to reduce cloud costs"
1. Read: [From Base Camp to Summit - Cost Management](https://technicalanxiety.com/basecamp-summit/)
2. Deploy: [Cost Management Policies](infrastructure/arm-templates/policies/)
3. Run: [Cost Optimization Queries](infrastructure/log-analytics/cost-optimization/)
4. **Expected Result:** 20-30% cost reduction

### "I need to improve security"
1. Read: [From Base Camp to Summit - Security Baseline](https://technicalanxiety.com/basecamp-summit/)
2. Deploy: [Security Policies](infrastructure/arm-templates/policies/)
3. Monitor: [Security Queries](infrastructure/log-analytics/security-monitoring/)
4. **Expected Result:** 100% policy compliance

### "I need a HIPAA-compliant environment"
1. Read: [Governance in Azure](https://technicalanxiety.com/azure-governance/)
2. Deploy: [Healthcare HIPAA Landing Zone](infrastructure/landing-zones/healthcare-hipaa/)
3. Validate: Compliance checklist
4. **Expected Result:** Production-ready in 2-4 weeks

## Real-World Impact

These templates and patterns have been proven across 100+ organizations:

| Metric | Impact |
|--------|--------|
| **Cost Savings** | 20-30% average reduction |
| **MTTR Reduction** | 60% faster incident response |
| **Manual Work** | 40% reduction in toil |
| **Tag Compliance** | 95%+ achievement rate |
| **Security Incidents** | Eliminated #1 cause (stale credentials) |

## Blog Articles

This repository implements concepts from these articles:

- [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/) - Five governance disciplines
- [Governance in Azure](https://technicalanxiety.com/azure-governance/) - Landing zones and management groups
- [Using Log Analytics](https://technicalanxiety.com/log-analytics/) - Actionable insights from logs
- [Operational Change Series](https://technicalanxiety.com/operations/) - Cloud operations transformation

See [BLOG-TO-CODE-MAPPING.md](BLOG-TO-CODE-MAPPING.md) for complete mapping.

## Prerequisites

- Azure subscription
- Azure CLI or PowerShell Az module
- Appropriate RBAC permissions (Contributor or Owner)
- Log Analytics workspace (for queries)

## Contributing

Contributions welcome! Found a better way to implement something? Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Blog:** [technicalanxiety.com](https://technicalanxiety.com)
- **Twitter:** [@anxiouslytech](https://twitter.com/anxiouslytech)
- **LinkedIn:** [Jason Rinehart](https://linkedin.com/in/rinehart76)

## Acknowledgments

Built from 20+ years of experience across healthcare, finance, manufacturing, and technology sectors. Special thanks to the Azure community and everyone who has shared their knowledge through blogs and open source.

---

*"Over 20+ years in technology, I've learned more from technical blogs than from any formal training. This site exists to pay that forward."* - Jason Rinehart
# Azure Cloud Things

**Version: 2.0.0 - Updated repository structure, enhanced security standards, and improved blog integration**

> Production-ready Azure governance, operations, and infrastructure templates from 20+ years of real-world experience.

[![Blog](https://img.shields.io/badge/Blog-Technical%20Anxiety-blue)](https://technicalanxiety.com)
[![Twitter](https://img.shields.io/twitter/follow/anxiouslytech?style=social)](https://twitter.com/anxiouslytech)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Jason%20Rinehart-blue)](https://linkedin.com/in/rinehart76)

## What is This?

This repository connects blog articles from [Technical Anxiety](https://technicalanxiety.com) to their practical implementations. Each article explains the "why" and "what" - this repository provides the "how" with actual code, queries, and templates you can use immediately.

> "If one person solves a problem faster because I documented what I learned, then this effort matters." - Jason Rinehart

**Architecture-First Approach**: Every template and pattern follows enterprise-grade standards with built-in scalability, security, and cost optimization.

## What's Inside

### 🏗️ Infrastructure & Governance
- **ARM Templates & Policies** - Enterprise governance implementing the five disciplines from [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/)
- **Landing Zones** - Production-ready environments including Healthcare HIPAA compliance
- **Alert Management** - Comprehensive alerting configurations for critical, security, and operational events
- All templates follow current Azure API versions and enterprise patterns

### 📊 Log Analytics & Monitoring  
- **Cost Optimization Queries** - Find unused resources, right-size VMs, identify waste (20-30% savings)
- **Security Monitoring** - Detect failed logins, brute force attacks, credential stuffing
- **Operational Health** - VM performance, backup status, compliance tracking
- **Dashboard Management** - Pre-built workbooks and visualization templates

### 🤖 Automation & Operations
- **Cost Management** - Auto-shutdown dev resources ($2-5k/month savings)
- **Security Automation** - Automated key rotation, public IP auditing, NSG enforcement  
- **Compliance Automation** - Tag enforcement (95%+ compliance target), policy remediation
- **Operational Runbooks** - VM health checks, proactive monitoring (60% MTTR reduction)

### 📚 Documentation & Guidance
- **Blog-to-Code Mapping** - Direct connections between articles and implementations
- **Progressive Complexity** - Basic examples building to advanced enterprise scenarios
- **Architecture Patterns** - Real-world impact metrics and trade-off analysis
- **Security-First Examples** - All templates demonstrate secure configuration patterns

## Quick Start

### 🚀 Basic: Find Cost Savings (5 minutes)
```bash
# Find unused resources costing you money
az monitor log-analytics query \
  --workspace <REPLACE_WITH_YOUR_WORKSPACE_ID> \
  --analytics-query @infrastructure/log-analytics/cost-optimization/unused-resources.kql
```

### 🏗️ Intermediate: Deploy Governance Policies (30 minutes)
```bash
# Deploy the five governance disciplines from "From Base Camp to Summit"
az policy set-definition create \
  --name "governance-initiative" \
  --definitions @infrastructure/arm-templates/policies/governance-initiative.json \
  --management-group <REPLACE_WITH_YOUR_MG_NAME>
```

### 🏥 Advanced: Deploy HIPAA-Compliant Landing Zone (2-4 weeks)
```bash
# Healthcare HIPAA-compliant landing zone with full governance
az deployment sub create \
  --location eastus \
  --template-file infrastructure/landing-zones/healthcare-hipaa/main.bicep \
  --parameters @infrastructure/landing-zones/healthcare-hipaa/main.parameters.json
```

**Security Note**: All examples use placeholder values (`<REPLACE_WITH_YOUR_VALUE>`) for sensitive information. Never commit actual credentials or keys to version control.

## Repository Structure

```
├── infrastructure/                 # Core infrastructure templates and patterns
│   ├── arm-templates/             # ARM templates organized by resource type
│   │   ├── alertschema/           # Alert configuration schemas
│   │   ├── platformtools/         # Platform management tools
│   │   └── policies/              # Governance policies (five disciplines)
│   ├── automation/                # PowerShell runbooks and automation
│   │   ├── compliance/            # Tag enforcement, policy remediation
│   │   ├── cost-management/       # Auto-shutdown, resource cleanup
│   │   ├── operational/           # Health checks, monitoring
│   │   └── security/              # Key rotation, access auditing
│   ├── log-analytics/             # KQL queries for actionable insights
│   │   ├── cost-optimization/     # Unused resources, right-sizing
│   │   ├── operational-health/    # VM performance, backup status
│   │   └── security-monitoring/   # Failed logins, threat detection
│   ├── landing-zones/             # Reference architectures
│   │   └── healthcare-hipaa/      # HIPAA-compliant environment
│   └── scripts/                   # Utility and deployment scripts
├── projects/                      # Complete solution implementations
│   ├── alertmanager/              # Alert management configurations
│   ├── dashboardmanager/          # Dashboard and workbook templates
│   └── updatemanager/             # Update and patch management
├── scripts/                       # Setup and configuration utilities
└── docs/                          # Additional documentation
```

**Organization Principle**: Templates are organized by both technology and business function, following enterprise naming conventions and clear separation of concerns.

## Use Cases by Experience Level

### 🟢 Getting Started: "I need to reduce cloud costs immediately"
**Time Investment:** 30 minutes | **Expected Savings:** 20-30%

1. **Learn the Why:** [From Base Camp to Summit - Cost Management](https://technicalanxiety.com/basecamp-summit/)
2. **Quick Wins:** Run [Cost Optimization Queries](infrastructure/log-analytics/cost-optimization/)
3. **Implement:** Deploy basic [Cost Management Policies](infrastructure/arm-templates/policies/)
4. **Measure:** Track savings with automated reporting

**Architecture Consideration:** Start with non-production environments to validate impact before applying to production workloads.

### 🟡 Intermediate: "I need comprehensive security governance"
**Time Investment:** 2-4 weeks | **Expected Outcome:** 100% policy compliance

1. **Understand the Framework:** [From Base Camp to Summit - Security Baseline](https://technicalanxiety.com/basecamp-summit/)
2. **Assess Current State:** Run [Security Monitoring Queries](infrastructure/log-analytics/security-monitoring/)
3. **Deploy Incrementally:** Implement [Security Policies](infrastructure/arm-templates/policies/) using phased approach
4. **Monitor Continuously:** Set up automated compliance reporting

**Trade-offs:** Initial deployment effort vs. long-term security posture improvement and reduced incident response costs.

### 🔴 Advanced: "I need a production-ready HIPAA environment"
**Time Investment:** 2-4 weeks | **Expected Outcome:** Audit-ready compliance

1. **Master the Concepts:** [Governance in Azure](https://technicalanxiety.com/azure-governance/)
2. **Plan Architecture:** Review [Healthcare HIPAA Landing Zone](infrastructure/landing-zones/healthcare-hipaa/) design
3. **Deploy with Governance:** Full landing zone with integrated compliance controls
4. **Validate Compliance:** Complete audit checklist and documentation

**Enterprise Pattern:** This approach scales to multiple business units and regulatory requirements beyond HIPAA.

## Real-World Impact & Validation

These templates and patterns have been proven across 100+ organizations with measurable results:

| **Business Outcome** | **Technical Implementation** | **Validation Method** |
|---------------------|----------------------------|----------------------|
| **20-30% Cost Reduction** | Cost optimization policies + unused resource queries | Monthly Azure cost analysis reports |
| **60% Faster Incident Response** | Proactive monitoring + automated alerting | Mean Time to Resolution (MTTR) metrics |
| **40% Less Manual Work** | Automation runbooks + policy enforcement | Time tracking and operational metrics |
| **95%+ Tag Compliance** | Automated tag enforcement policies | Azure Resource Graph compliance queries |
| **Zero Stale Credential Incidents** | Automated key rotation + access reviews | Security incident tracking and audit logs |

**Cost Consciousness Example:** The auto-shutdown policies alone have saved organizations $32,000/month by preventing forgotten development resources from running 24/7.

**Security ROI:** Organizations report that implementing security governance upfront costs 10x less than retrofitting security after deployment.

## Blog Integration & Learning Path

This repository implements concepts from these Technical Anxiety articles with progressive complexity:

### Foundation Articles
- **[Governance in Azure](https://technicalanxiety.com/azure-governance/)** - Core concepts and management groups
- **[From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/)** - Five governance disciplines with real-world examples
- **[Using Log Analytics](https://technicalanxiety.com/log-analytics/)** - Beyond basic logging to actionable insights

### Advanced Operations
- **[Operational Change Series](https://technicalanxiety.com/operations/)** - Cloud operations transformation patterns
- **AI and Intelligent Operations** - Future-focused automation approaches

**Complete Mapping:** See [BLOG-TO-CODE-MAPPING.md](BLOG-TO-CODE-MAPPING.md) for detailed connections between articles and implementations.

**Learning Approach:** Each article explains the architectural reasoning and business context, while this repository provides the production-ready implementation with security best practices built-in.

## Prerequisites & Security Requirements

### Technical Prerequisites
- **Azure Subscription** with appropriate RBAC permissions (Contributor or Owner at minimum)
- **Azure CLI** (latest version) or **PowerShell Az module** (v5.0+)
- **Log Analytics Workspace** for query execution and monitoring
- **Management Group Structure** (recommended for enterprise governance)

### Security & Compliance
- **Key Vault Integration:** All sensitive values should be stored in Azure Key Vault
- **Environment Variables:** Use `${ENVIRONMENT_VARIABLE}` pattern for configuration
- **Parameter Security:** Templates use `@secure()` decorator for sensitive parameters
- **No Hardcoded Secrets:** All examples use placeholder format `<REPLACE_WITH_YOUR_VALUE>`

### Recommended Setup Sequence
1. **Start Small:** Deploy to development subscription first
2. **Validate Impact:** Run cost and security queries to establish baseline
3. **Scale Gradually:** Apply governance policies in phases
4. **Monitor Continuously:** Set up automated compliance and cost reporting

**Enterprise Consideration:** For multi-subscription environments, establish management group hierarchy before deploying governance policies.

## Contributing & Community

**Architecture-First Contributions Welcome!** Found a better way to implement something? Please contribute:

### Contribution Guidelines
1. **Reference the Blog:** Connect your improvement to relevant [Technical Anxiety](https://technicalanxiety.com) articles
2. **Follow Security Standards:** Use secure parameter patterns and Key Vault integration
3. **Document Trade-offs:** Explain architectural decisions and alternatives considered
4. **Provide Real-World Context:** Include cost implications and scalability considerations
5. **Update Mappings:** Maintain [BLOG-TO-CODE-MAPPING.md](BLOG-TO-CODE-MAPPING.md) connections

### Process
1. Fork the repository
2. Create a feature branch with descriptive name
3. Implement changes following enterprise patterns
4. Test in non-production environment first
5. Submit pull request with architectural reasoning

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines and coding standards.

**Community Focus:** This repository exists to accelerate enterprise Azure adoption through shared knowledge and proven patterns.

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
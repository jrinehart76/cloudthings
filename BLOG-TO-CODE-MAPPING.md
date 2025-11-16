# Blog-to-Code Mapping

This document connects blog articles from [Technical Anxiety](https://technicalanxiety.com) to their practical implementations in this repository.

## Purpose

> "If one person solves a problem faster because I documented what I learned, then this effort matters." - Jason Rinehart

Each blog article explains the "why" and "what." This repository provides the "how" - actual code, queries, and templates you can use immediately.

## 📚 Blog Article Index

### Governance

#### [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/)
**Topic:** Why Your Cloud Migration Will Fail Without Proper Governance

**Implementation:**
- **Policies:** [`/infrastructure/arm-templates/policies/`](infrastructure/arm-templates/policies/)
  - Complete policy set for five governance disciplines
  - Policy initiative JSON for deployment
  - Enforcement examples

- **Deployment Guide:** [`/infrastructure/arm-templates/policies/DEPLOYMENT-GUIDE.md`](infrastructure/arm-templates/policies/DEPLOYMENT-GUIDE.md)
  - Week-by-week implementation plan
  - Phased approach following "base camp" metaphor
  - Azure CLI commands for each phase
  - Success metrics and validation

- **Quick Reference:** [`/infrastructure/arm-templates/policies/FIVE-DISCIPLINES.md`](infrastructure/arm-templates/policies/FIVE-DISCIPLINES.md)
  - One-page summary of each discipline
  - Real-world impact examples
  - Quick win recommendations
  - Implementation checklist

**Key Quotes Implemented:**
- "Organizations overspend by 200-400% in first quarter" → Cost management policies
- "Security retrofits cost 10x more" → Security baseline policies
- "Temporary permissions become permanent" → Identity baseline policies
- "We'll organize things later never works" → Resource consistency policies
- "Automation actually accelerates delivery" → Deployment acceleration policies

**Real-World Examples:**
- $40k dev environment story → Auto-shutdown policies
- 10x security retrofit cost → Security-first approach
- 6-month remediation → Proactive governance

---

#### [Governance in Azure?](https://technicalanxiety.com/azure-governance/)
**Topic:** Introduction to Azure Governance Concepts

**Implementation:**
- **Landing Zones:** [`/infrastructure/landing-zones/`](infrastructure/landing-zones/)
  - Healthcare HIPAA landing zone
  - Enterprise standard landing zone
  - SMB landing zone
  - Pre-configured governance

- **Management Groups:** [`/infrastructure/landing-zones/*/management-groups.bicep`](infrastructure/landing-zones/)
  - Hierarchical structure
  - Policy inheritance
  - RBAC assignments

**Practical Application:**
- Management group design patterns
- Policy assignment strategies
- RBAC role definitions
- Subscription organization

---

### Log Analytics

#### [Using Log Analytics to... view logs](https://technicalanxiety.com/log-analytics/)
**Topic:** Beyond Basic Log Viewing - Actionable Insights

**Implementation:**
- **Query Library:** [`/infrastructure/log-analytics/`](infrastructure/log-analytics/)
  - Cost optimization queries
  - Security monitoring queries
  - Operational health queries
  - Performance analysis queries

- **Cost Optimization:**
  - [`unused-resources.kql`](infrastructure/log-analytics/cost-optimization/unused-resources.kql) - Find waste
  - [`oversized-vms.kql`](infrastructure/log-analytics/cost-optimization/oversized-vms.kql) - Right-size VMs
  - [`orphaned-disks.kql`](infrastructure/log-analytics/cost-optimization/orphaned-disks.kql) - Remove unused disks

- **Security Monitoring:**
  - [`failed-logins.kql`](infrastructure/log-analytics/security-monitoring/failed-logins.kql) - Detect attacks
  - Brute force detection
  - Credential stuffing identification

- **Operational Health:**
  - [`vm-performance.kql`](infrastructure/log-analytics/operational-health/vm-performance.kql) - Performance issues
  - [`backup-status.kql`](infrastructure/log-analytics/operational-health/backup-status.kql) - Backup monitoring

**Key Insights:**
- "Log Analytics isn't just about viewing logs" → Actionable queries
- "Extract insights that drive decisions" → Business-focused queries
- "Reduce MTTR by 60%" → Proactive monitoring queries

---

### Operations

#### [Operational Change, Part 1](https://technicalanxiety.com/operational-change-part-1/)
**Topic:** Cloud Operations Transformation

**Implementation:**
- **Automation Runbooks:** [`/infrastructure/automation/`](infrastructure/automation/) *(coming soon)*
  - Cost management automation
  - Security automation
  - Compliance automation

- **Monitoring:** [`/infrastructure/log-analytics/operational-health/`](infrastructure/log-analytics/operational-health/)
  - VM performance monitoring
  - Backup status tracking
  - Update compliance checking

**Operational Patterns:**
- Automated remediation
- Proactive monitoring
- Self-service capabilities
- Continuous compliance

---

#### [Operational Change, Part 2](https://technicalanxiety.com/operational-change-part-2/)
**Topic:** AI and Intelligent Operations

**Implementation:**
- **Intelligent Monitoring:** [`/infrastructure/log-analytics/`](infrastructure/log-analytics/)
  - Anomaly detection queries
  - Predictive analytics
  - Pattern recognition

**Future Enhancements:**
- Machine learning integration
- Predictive scaling
- Automated incident response

---

## 🎯 Quick Navigation by Use Case

### "I need to reduce cloud costs"
1. Read: [From Base Camp to Summit - Cost Management](https://technicalanxiety.com/basecamp-summit/)
2. Deploy: [Cost Management Policies](infrastructure/arm-templates/policies/)
3. Run: [Cost Optimization Queries](infrastructure/log-analytics/cost-optimization/)
4. Expected: 20-30% cost reduction

### "I need to improve security"
1. Read: [From Base Camp to Summit - Security Baseline](https://technicalanxiety.com/basecamp-summit/)
2. Deploy: [Security Policies](infrastructure/arm-templates/policies/)
3. Monitor: [Security Queries](infrastructure/log-analytics/security-monitoring/)
4. Expected: 100% policy compliance

### "I need to set up a new Azure environment"
1. Read: [Governance in Azure](https://technicalanxiety.com/azure-governance/)
2. Choose: [Landing Zone Template](infrastructure/landing-zones/)
3. Deploy: Follow landing zone README
4. Expected: Production-ready in 2-4 weeks

### "I need better monitoring"
1. Read: [Using Log Analytics](https://technicalanxiety.com/log-analytics/)
2. Deploy: [Log Analytics Queries](infrastructure/log-analytics/)
3. Create: Custom workbooks
4. Expected: 60% reduction in MTTR

### "I need HIPAA compliance"
1. Read: [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/)
2. Deploy: [Healthcare HIPAA Landing Zone](infrastructure/landing-zones/healthcare-hipaa/)
3. Validate: Compliance checklist
4. Expected: HIPAA-ready environment

## 📊 Impact Metrics

### Cost Management
| Blog Claim | Implementation | Validation |
|------------|----------------|------------|
| 200-400% overspend without governance | Cost policies + budgets | Run unused-resources.kql |
| 20-30% savings from unused resources | unused-resources.kql | Monthly cost reports |
| 15-25% savings from right-sizing | oversized-vms.kql | VM utilization metrics |

### Security
| Blog Claim | Implementation | Validation |
|------------|----------------|------------|
| 10x cost of security retrofits | Security-first landing zones | Deployment time comparison |
| Early threat detection | failed-logins.kql | Security incident logs |
| 100% policy compliance | Policy enforcement | Compliance dashboard |

### Operations
| Blog Claim | Implementation | Validation |
|------------|----------------|------------|
| 60% reduction in MTTR | vm-performance.kql | Incident response times |
| 40% reduction in manual work | Automation runbooks | Time tracking |
| 35-40% deployment efficiency | IaC templates | Deployment metrics |

## 🔄 Continuous Updates

This mapping is updated as new blog articles are published and new implementations are added.

### Recently Added
- **2025-01-15:** From Base Camp to Summit implementation
- **2025-01-15:** Log Analytics query library
- **2025-01-15:** Healthcare HIPAA landing zone

### Coming Soon
- Automation runbook library
- Azure Workbooks for governance
- Case study implementations
- Architecture decision records

## 🤝 Contributing

Found a better way to implement something from the blog? Contributions welcome!

1. Reference the blog article
2. Explain the improvement
3. Provide working code
4. Update this mapping

## 📖 Reading Order

### For Cloud Beginners
1. [Governance in Azure](https://technicalanxiety.com/azure-governance/) → [Landing Zones](infrastructure/landing-zones/)
2. [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/) → [Policies](infrastructure/arm-templates/policies/)
3. [Using Log Analytics](https://technicalanxiety.com/log-analytics/) → [Queries](infrastructure/log-analytics/)

### For Experienced Architects
1. [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/) → [Five Disciplines](infrastructure/arm-templates/policies/FIVE-DISCIPLINES.md)
2. [Operational Change Series](https://technicalanxiety.com/operations/) → [Automation](infrastructure/automation/)
3. Review landing zones for patterns

### For Security Teams
1. [From Base Camp to Summit - Security](https://technicalanxiety.com/basecamp-summit/) → [Security Policies](infrastructure/arm-templates/policies/)
2. [Healthcare HIPAA Landing Zone](infrastructure/landing-zones/healthcare-hipaa/)
3. [Security Monitoring Queries](infrastructure/log-analytics/security-monitoring/)

### For Finance/FinOps Teams
1. [From Base Camp to Summit - Cost](https://technicalanxiety.com/basecamp-summit/) → [Cost Policies](infrastructure/arm-templates/policies/)
2. [Cost Optimization Queries](infrastructure/log-analytics/cost-optimization/)
3. Budget and tagging templates

## 🔗 External Resources

### Azure Documentation
- [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Policy](https://docs.microsoft.com/azure/governance/policy/)
- [Log Analytics](https://docs.microsoft.com/azure/azure-monitor/logs/)

### Community
- [Technical Anxiety Blog](https://technicalanxiety.com)
- [Twitter: @anxiouslytech](https://twitter.com/anxiouslytech)
- [LinkedIn: Jason Rinehart](https://linkedin.com/in/rinehart76)

---

*"Over 20+ years in technology, I've learned more from technical blogs than from any formal training. This site exists to pay that forward."* - Jason Rinehart

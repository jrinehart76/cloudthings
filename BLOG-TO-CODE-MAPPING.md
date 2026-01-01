# Blog-to-Code Mapping

This document connects blog articles from [Technical Anxiety](https://technicalanxiety.com) to their practical implementations in this repository.

## Purpose

> "If one person solves a problem faster because I documented what I learned, then this effort matters." - Jason Rinehart

Each blog article explains the "why" and "what." This repository provides the "how" - actual code, queries, and templates you can use immediately.

## 📚 Blog Article Index

### Monitoring & Operations

#### [Monitoring Foundation: The Reference Implementation](https://technicalanxiety.com/monitoring-reference/)

**Topic:** Deploy the Beyond Azure Monitor patterns as infrastructure code

**Implementation:**

- **Complete Monitoring Stack:** [`/monitoring-foundation/`](monitoring-foundation/)
  - Main orchestration template with environment-aware thresholds
  - Log Analytics workspace with saved KQL searches from the series
  - Action groups for email and ITSM webhook integration
  - Context-aware alert rules with business hours intelligence
  - Operational workbooks for NOC teams

- **Bicep Templates:**
  - [`main.bicep`](monitoring-foundation/main.bicep) - Complete deployment orchestration
  - [`modules/log-analytics.bicep`](monitoring-foundation/modules/log-analytics.bicep) - Workspace with saved searches
  - [`modules/action-groups.bicep`](monitoring-foundation/modules/action-groups.bicep) - Notification routing
  - [`modules/alert-rules.bicep`](monitoring-foundation/modules/alert-rules.bicep) - Intelligent alert rules
  - [`modules/workbooks.bicep`](monitoring-foundation/modules/workbooks.bicep) - Operational dashboards

- **KQL Query Library:** [`/monitoring-foundation/queries/`](monitoring-foundation/queries/)
  - [`context-aware-cpu.kql`](monitoring-foundation/queries/context-aware-cpu.kql) - Business hours CPU monitoring
  - [`dynamic-baseline.kql`](monitoring-foundation/queries/dynamic-baseline.kql) - Historical performance comparison
  - [`service-correlation.kql`](monitoring-foundation/queries/service-correlation.kql) - Cross-service error correlation
  - [`capacity-prediction.kql`](monitoring-foundation/queries/capacity-prediction.kql) - 7-day capacity forecasting
  - [`anomaly-detection.kql`](monitoring-foundation/queries/anomaly-detection.kql) - Error rate spike detection

- **Deployment Automation:**
  - [`Deploy-MonitoringFoundation.ps1`](monitoring-foundation/scripts/Deploy-MonitoringFoundation.ps1) - PowerShell deployment script
  - Environment-specific parameter files for dev, staging, and production
  - Validation-only mode for dry runs

**Key Patterns Implemented:**

- **Context-Aware Monitoring:** CPU thresholds adjust based on business hours (70% during business, 85% after hours)
- **Dynamic Baselines:** Response time alerts compare against 14-day historical patterns instead of static thresholds
- **Predictive Alerting:** Capacity prediction alerts warn 7 days before resources hit 85% utilization
- **Anomaly Detection:** Error rate monitoring uses statistical analysis to reduce false positives
- **Environment Intelligence:** Thresholds automatically adjust based on dev/staging/prod deployment

**Enterprise Architecture Benefits:**

- **Cost Optimization:** Prevents over-alerting in dev (90% CPU threshold) vs production (75% threshold)
- **Operational Efficiency:** Workbooks surface actionable information instead of raw metrics
- **ITSM Integration:** Webhook support for ServiceNow, PagerDuty, and other ticketing systems
- **Scalable Deployment:** Single command deploys complete monitoring stack across environments

**Real-World Impact:**

- Reduces alert noise by 60-80% through intelligent thresholds
- Enables proactive capacity management with 7-day forecasting
- Correlates application errors with infrastructure events for faster MTTR
- Provides NOC teams with actionable dashboards instead of metric overload

**Quick Start:**
```bash
# Deploy to production
az deployment group create \
  --resource-group rg-monitoring \
  --template-file monitoring-foundation/main.bicep \
  --parameters @monitoring-foundation/examples/parameters.prod.json
```

---

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

- **Automation Runbooks:** [`/infrastructure/automation/`](infrastructure/automation/)
  - **Cost Management:**
    - [`shutdown-dev-resources.ps1`](infrastructure/automation/cost-management/shutdown-dev-resources.ps1) - Auto-shutdown (saves $2-5k/month)
    - Snapshot cleanup
    - Orphaned resource removal
  
  - **Security:**
    - [`rotate-storage-keys.ps1`](infrastructure/automation/security/rotate-storage-keys.ps1) - Automated key rotation
    - Public IP auditing
    - NSG rule enforcement
  
  - **Compliance:**
    - [`tag-enforcement.ps1`](infrastructure/automation/compliance/tag-enforcement.ps1) - Tag compliance (95%+ target)
    - Backup verification
    - Policy remediation
  
  - **Operational:**
    - [`vm-health-check.ps1`](infrastructure/automation/operational/vm-health-check.ps1) - Proactive monitoring (60% MTTR reduction)
    - Performance baselines
    - Resource inventory

- **Monitoring:** [`/infrastructure/log-analytics/operational-health/`](infrastructure/log-analytics/operational-health/)
  - VM performance monitoring
  - Backup status tracking
  - Update compliance checking

**Operational Patterns:**

- Automated remediation (40% reduction in manual work)
- Proactive monitoring (2-4 hour early detection)
- Self-service capabilities
- Continuous compliance

**Real-World Impact:**

- $32,000/month savings (dev environment auto-shutdown)
- 60% reduction in MTTR
- 95%+ tag compliance
- Eliminated #1 security incident cause (stale credentials)

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

### "I need intelligent monitoring that reduces noise"

1. Read: [Monitoring Foundation: The Reference Implementation](https://technicalanxiety.com/monitoring-reference/)
2. Deploy: [Monitoring Foundation](monitoring-foundation/)
3. Customize: Adjust business hours and thresholds in alert rules
4. Expected: 60-80% reduction in alert noise, proactive capacity warnings

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

### Monitoring & Alerting

| Blog Claim | Implementation | Validation |
| ---------- | -------------- | ---------- |
| 60-80% reduction in alert noise | Context-aware thresholds + dynamic baselines | Alert volume before/after |
| 7-day capacity forecasting | capacity-prediction.kql | Actual vs predicted capacity |
| Business hours intelligence | context-aware-cpu.kql | Threshold adjustment verification |
| Cross-service correlation | service-correlation.kql | MTTR improvement metrics |

### Cost Management

| Blog Claim | Implementation | Validation |
| ---------- | -------------- | ---------- |
| 200-400% overspend without governance | Cost policies + budgets | Run unused-resources.kql |
| 20-30% savings from unused resources | unused-resources.kql | Monthly cost reports |
| 15-25% savings from right-sizing | oversized-vms.kql | VM utilization metrics |

### Security

| Blog Claim | Implementation | Validation |
| ---------- | -------------- | ---------- |
| 10x cost of security retrofits | Security-first landing zones | Deployment time comparison |
| Early threat detection | failed-logins.kql | Security incident logs |
| 100% policy compliance | Policy enforcement | Compliance dashboard |

### Operational Efficiency

| Blog Claim | Implementation | Validation |
| ---------- | -------------- | ---------- |
| 60% reduction in MTTR | vm-performance.kql | Incident response times |
| 40% reduction in manual work | Automation runbooks | Time tracking |
| 35-40% deployment efficiency | IaC templates | Deployment metrics |

## � Continuous Updates

This mapping is updated as new blog articles are published and new implementations are added.

### Recently Added

- **2025-01-01:** Monitoring Foundation - Complete Beyond Azure Monitor implementation
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
4. [Monitoring Foundation](https://technicalanxiety.com/monitoring-reference/) → [Monitoring Foundation](monitoring-foundation/)

### For Experienced Architects

1. [From Base Camp to Summit](https://technicalanxiety.com/basecamp-summit/) → [Five Disciplines](infrastructure/arm-templates/policies/FIVE-DISCIPLINES.md)
2. [Monitoring Foundation](https://technicalanxiety.com/monitoring-reference/) → [Intelligent Monitoring](monitoring-foundation/)
3. [Operational Change Series](https://technicalanxiety.com/operations/) → [Automation](infrastructure/automation/)
4. Review landing zones for patterns

### For Operations Teams

1. [Monitoring Foundation](https://technicalanxiety.com/monitoring-reference/) → [Intelligent Monitoring](monitoring-foundation/)
2. [Using Log Analytics](https://technicalanxiety.com/log-analytics/) → [Operational Queries](infrastructure/log-analytics/operational-health/)
3. [Operational Change Series](https://technicalanxiety.com/operations/) → [Automation Runbooks](infrastructure/automation/)

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

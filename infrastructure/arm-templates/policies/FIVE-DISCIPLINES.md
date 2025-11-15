# The Five Governance Disciplines - Quick Reference

Based on [From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/)

## 1. Cost Management 💰

**What it is:** Policies to control and optimize spending through budgets, monitoring, and cost allocation strategies.

**Why you'll fail without it:** Cloud costs escalate immediately. Organizations consistently overspend by 200-400% in their first quarter without proper cost governance.

**Key Policies:**
- Required tags for cost allocation (CostCenter, Project, Owner)
- Budget alerts at 80% threshold
- Auto-shutdown schedules for non-production resources
- Reserved instance recommendations
- Unused resource identification

**Real-World Impact:**
> "One energy sector client spun up development environments that ran 24/7 because nobody implemented policy to shut them down after hours. Six months later, they were spending $40,000 monthly on resources that should have cost $8,000."

**Quick Win:** Deploy tagging policies in audit mode today. Understand your cost allocation gaps before they become budget overruns.

---

## 2. Security Baseline 🔒

**What it is:** Security policies and controls including firewalls, network security groups, encryption, threat detection, and compliance standards.

**Why you'll fail without it:** Security retrofits cost 10x more than building it correctly from the start. Establishing security after deployment is like installing airbags after the crash.

**Key Policies:**
- Storage account firewall rules required
- No public IP addresses without approval
- Encryption at rest enforced
- Network security groups required
- Diagnostic logging enabled
- No classic (legacy) resources

**Real-World Impact:**
> "One client discovered their 'secure' environment had publicly accessible storage accounts containing patient data. The remediation, investigation, and compliance response consumed six months of engineering time."

**Quick Win:** Block public IP creation today. Prevents the most common accidental exposure vector.

---

## 3. Identity Baseline 👤

**What it is:** Managing identities and access through RBAC, MFA, Privileged Identity Management, and least privilege principles.

**Why you'll fail without it:** Improper access control creates immediate risk. Every over-privileged account is a potential security incident waiting to happen.

**Key Policies:**
- MFA required for all users
- Just-in-time access for privileged operations
- Service principals with minimal permissions
- Regular access reviews
- Conditional access policies
- No permanent owner assignments

**Real-World Impact:**
> "Organizations that grant broad permissions 'temporarily' discover those permissions become permanent because nobody has time to clean them up later."

**Quick Win:** Implement Privileged Identity Management for subscription owners. Require justification and time-limited elevation.

---

## 4. Resource Consistency 📋

**What it is:** Uniform organization through naming conventions, tagging strategies, and structured management groups, subscriptions, and resource groups.

**Why you'll fail without it:** Inconsistent resource organization makes everything harder. The "we'll organize things later" approach never works. Later never comes.

**Key Policies:**
- Naming convention enforcement
- Required tags (Environment, Owner, CostCenter, Application)
- Allowed locations/regions
- Resource group structure standards
- Subscription organization rules

**Real-World Impact:**
> "I've seen teams spend weeks just trying to identify which resources belong to which application because nobody enforced consistency from day one."

**Quick Win:** Enforce three required tags today: Environment, Owner, CostCenter. Block resource creation without them.

---

## 5. Deployment Acceleration 🚀

**What it is:** Automating and standardizing deployments through Infrastructure as Code (ARM, Bicep, Terraform) and CI/CD pipelines.

**Why you'll fail without it:** Manual deployments are slow, error-prone, and inconsistent. Without automation, every environment becomes a unique snowflake.

**Key Policies:**
- All infrastructure deployed via IaC
- Peer review required for infrastructure changes
- Automated testing in pipelines
- Diagnostic settings deployed automatically
- Configuration drift detection
- Immutable infrastructure patterns

**Real-World Impact:**
> "Organizations that automated environment provisioning increased deployment efficiency by 35-40% while simultaneously maintaining stronger governance controls."

**Quick Win:** Deploy diagnostic settings via policy. Every new resource automatically sends logs to Log Analytics without manual configuration.

---

## The Interconnection

These five disciplines are not independent. They reinforce each other:

```
Cost Management ←→ Resource Consistency
      ↓                    ↓
Security Baseline ←→ Identity Baseline
      ↓                    ↓
    Deployment Acceleration
```

**Example:** A resource created without proper tagging (Resource Consistency) is:
- Harder to secure (Security Baseline)
- Impossible to cost-allocate (Cost Management)
- Difficult to govern access (Identity Baseline)
- Can't be automated (Deployment Acceleration)

**That single resource becomes five problems instead of one.**

---

## Implementation Priority

### Week 1-2: Foundation
1. Deploy management group structure
2. Enable cost budgets and alerts
3. Implement tagging policies (audit mode)

### Week 3-4: Security
1. Block public IPs
2. Enforce storage security
3. Enable diagnostic logging

### Week 5-6: Consistency
1. Enforce required tags (deny mode)
2. Implement naming conventions
3. Restrict allowed locations

### Week 7-8: Automation
1. Deploy IaC pipelines
2. Automate diagnostic settings
3. Enable auto-shutdown for dev

### Ongoing: Optimization
1. Monitor compliance
2. Remediate gaps
3. Iterate based on data

---

## Success Criteria

You've successfully implemented governance when:

✅ **Cost Management:** Spending stays within 5% of budget  
✅ **Security Baseline:** 100% compliance with security policies  
✅ **Identity Baseline:** Zero standing privileged access  
✅ **Resource Consistency:** 95%+ resources properly tagged  
✅ **Deployment Acceleration:** 90%+ deployments via IaC  

---

## The Bottom Line

**Governance is not optional infrastructure.**

Organizations that skip governance fundamentals always end up rebuilding their environments later, at significantly higher cost and risk.

The question isn't whether you'll implement proper governance. It's whether you'll do it proactively when it's cheaper and safer, or reactively after you've already created problems that threaten your entire migration program.

**Choose wisely.**

---

## Quick Commands

### Check Compliance
```bash
az policy state summarize --management-group "mg-root"
```

### Deploy Governance Initiative
```bash
az policy set-definition create \
  --name "governance-foundation" \
  --definitions @governance-initiative.json
```

### Remediate Non-Compliance
```bash
az policy remediation create \
  --name "fix-tags" \
  --policy-assignment "require-tags"
```

### Cost Analysis
```bash
az consumption usage list \
  --start-date 2025-01-01 \
  --end-date 2025-01-31 \
  --query "[].{Cost:pretaxCost,Resource:instanceName}"
```

---

*Source: [From Base Camp to Summit - Why Your Cloud Migration Will Fail Without Proper Governance](https://www.technicalanxiety.com/basecamp-summit/)*

# Governance Policy Deployment Guide

## From Base Camp to Summit: A Phased Approach

This guide implements the governance principles from [From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/). Like climbing Everest, cloud governance requires deliberate progress through established base camps.

## The Problem We're Solving

Most cloud migrations fail because organizations skip governance fundamentals. They treat cloud adoption like a sprint when it's actually a staged ascent. The result:

- **200-400% cost overruns** in the first quarter
- **Security retrofits** that cost 10x more than building correctly
- **Technical debt** that requires complete environment rebuilds
- **Operational chaos** that prevents scaling

## The Solution: Governance-First Approach

### Phase 1: Base Camp - Foundation (Week 1-2)

**Objective:** Establish the foundation before migrating any workloads.

#### 1. Deploy Management Group Structure

```bash
# Create management group hierarchy
az account management-group create \
  --name "mg-enterprise-root" \
  --display-name "Enterprise Root"

az account management-group create \
  --name "mg-platform" \
  --parent "mg-enterprise-root" \
  --display-name "Platform"

az account management-group create \
  --name "mg-landing-zones" \
  --parent "mg-enterprise-root" \
  --display-name "Landing Zones"
```

#### 2. Enable Cost Management (Audit Mode)

```bash
# Deploy tagging policy in audit mode
az policy assignment create \
  --name "audit-cost-center-tag" \
  --display-name "Audit: Require CostCenter Tag" \
  --policy "audit-resources-without-tags.json" \
  --params '{"tagName":{"value":"CostCenter"}}' \
  --scope "/providers/Microsoft.Management/managementGroups/mg-enterprise-root"
```

**Why audit first?** Understand current state before enforcing. Gives teams time to adapt.

#### 3. Set Up Cost Budgets

```bash
# Create budget with alerts
az consumption budget create \
  --budget-name "monthly-budget" \
  --amount 10000 \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2026-12-31 \
  --notifications \
    threshold=80 \
    operator=GreaterThan \
    contact-emails="finance@company.com"
```

**Expected Outcome:** Visibility into spending patterns before they become problems.

### Phase 2: Camp 1 - Security Hardening (Week 3-4)

**Objective:** Establish security baseline before workload migration.

#### 1. Enable Storage Account Security

```bash
# Enforce storage account firewall
az policy assignment create \
  --name "enforce-storage-firewall" \
  --policy "enforce-storage-account-firewall.json" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"

# Enforce service endpoints
az policy assignment create \
  --name "enforce-storage-endpoints" \
  --policy "enforce-storage-account-endpoints.json" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
```

#### 2. Block Public IP Assignments

```bash
az policy assignment create \
  --name "deny-public-ips" \
  --policy "enforce-no-public-ips.json" \
  --params '{"effect":{"value":"Deny"}}' \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
```

**Why this matters:** Prevents accidental exposure of resources to the internet.

#### 3. Enable Diagnostic Settings

```bash
# Deploy Log Analytics diagnostic policies
for policy in infrastructure/arm-templates/policies/enforce-log-analytics/*.json; do
  policy_name=$(basename "$policy" .json)
  az policy assignment create \
    --name "$policy_name" \
    --policy "$policy" \
    --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
done
```

**Expected Outcome:** All resources automatically send logs to centralized monitoring.

### Phase 3: Camp 2 - Resource Consistency (Week 5-6)

**Objective:** Enforce organizational standards before environment grows.

#### 1. Enforce Required Tags

```bash
# Transition from audit to deny for critical tags
az policy assignment create \
  --name "require-cost-center" \
  --policy "audit-resources-without-tags.json" \
  --params '{"tagName":{"value":"CostCenter"},"effect":{"value":"Deny"}}' \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"

az policy assignment create \
  --name "require-environment" \
  --policy "audit-resources-without-tags.json" \
  --params '{"tagName":{"value":"Environment"},"effect":{"value":"Deny"}}' \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"

az policy assignment create \
  --name "require-owner" \
  --policy "audit-resources-without-tags.json" \
  --params '{"tagName":{"value":"Owner"},"effect":{"value":"Deny"}}' \
  --scope "/providers/Microsoft.Management/managementGroups/mg-landing-zones"
```

#### 2. Enforce Naming Conventions

Create custom policy for naming standards:

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "name",
          "match": "vm-[a-z]{3}-[a-z]{3}-[0-9]{3}"
        }
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
```

**Expected Outcome:** Consistent resource naming that enables automation and cost tracking.

### Phase 4: Camp 3 - Deployment Acceleration (Week 7-8)

**Objective:** Automate everything before scaling operations.

#### 1. Set Up Infrastructure as Code Pipeline

```yaml
# Azure DevOps pipeline example
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - infrastructure/**

stages:
  - stage: Validate
    jobs:
      - job: PolicyValidation
        steps:
          - task: AzureCLI@2
            inputs:
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Validate all policy definitions
                for policy in infrastructure/arm-templates/policies/*.json; do
                  az policy definition validate --rules "$policy"
                done

  - stage: Deploy
    jobs:
      - job: DeployPolicies
        steps:
          - task: AzureCLI@2
            inputs:
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Deploy governance initiative
                az policy set-definition create \
                  --name "governance-foundation" \
                  --definitions @infrastructure/arm-templates/policies/governance-initiative.json
```

#### 2. Enable Auto-Shutdown for Dev Resources

```bash
az policy assignment create \
  --name "enforce-dev-shutdown" \
  --policy "enforce-shutdown-schedule.json" \
  --params '{"effect":{"value":"DeployIfNotExists"}}' \
  --scope "/subscriptions/{dev-subscription-id}"
```

**Expected Outcome:** 40% reduction in manual deployment work, 35% faster provisioning.

### Phase 5: Summit - Continuous Governance (Ongoing)

**Objective:** Monitor, measure, and iterate on governance posture.

#### 1. Set Up Compliance Dashboard

```bash
# Create compliance report
az policy state summarize \
  --management-group "mg-enterprise-root" \
  --query "results[].{Policy:policyDefinitionName, Compliant:resourceDetails.complianceState}" \
  --output table
```

#### 2. Implement Policy Remediation

```bash
# Remediate non-compliant resources
az policy remediation create \
  --name "remediate-tags" \
  --policy-assignment "require-cost-center" \
  --resource-discovery-mode ReEvaluateCompliance
```

#### 3. Monthly Governance Review

- Review policy compliance trends
- Analyze cost optimization opportunities
- Update policies based on new requirements
- Document lessons learned

## Success Metrics

Track these KPIs to measure governance effectiveness:

### Cost Management
- **Target:** Stay within 5% of budget
- **Measure:** Monthly spend vs. budget
- **Action:** Alert at 80% threshold

### Security Baseline
- **Target:** 100% compliance with security policies
- **Measure:** Policy compliance score
- **Action:** Automated remediation for critical gaps

### Resource Consistency
- **Target:** 95% of resources properly tagged
- **Measure:** Tag compliance rate
- **Action:** Block untagged resource creation

### Deployment Acceleration
- **Target:** 90% of deployments via IaC
- **Measure:** Manual vs. automated deployment ratio
- **Action:** Deprecate manual deployment access

## Common Pitfalls to Avoid

### ❌ Don't Do This

1. **Deploy workloads before governance** - Results in expensive retrofits
2. **Start with Deny policies** - Causes immediate friction without understanding impact
3. **Skip cost controls** - Leads to 200-400% overspend
4. **Grant broad permissions temporarily** - Temporary becomes permanent
5. **Manual policy deployment** - Doesn't scale, creates drift

### ✅ Do This Instead

1. **Governance before workloads** - Build the foundation first
2. **Audit → Deny progression** - Understand impact before enforcing
3. **Cost budgets from day one** - Prevent surprises
4. **Least privilege by default** - Easier to grant than revoke
5. **Automate policy deployment** - Consistent, repeatable, scalable

## Validation Checklist

Before migrating workloads, verify:

- [ ] Management group structure deployed
- [ ] Cost budgets and alerts configured
- [ ] Required tags enforced (CostCenter, Environment, Owner)
- [ ] Security baseline policies active
- [ ] Diagnostic settings enabled for all resource types
- [ ] Network security policies enforced
- [ ] Identity baseline configured
- [ ] IaC pipeline operational
- [ ] Compliance dashboard accessible
- [ ] Remediation process documented

## Next Steps

1. **Review current state** - Run compliance assessment
2. **Plan phased rollout** - Don't rush, follow the base camps
3. **Communicate changes** - Teams need time to adapt
4. **Monitor and iterate** - Governance evolves with your needs

## Resources

- [Blog Article: From Base Camp to Summit](https://www.technicalanxiety.com/basecamp-summit/)
- [Azure Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Policy Samples](https://github.com/Azure/azure-policy)
- [Landing Zone Accelerator](https://github.com/Azure/Enterprise-Scale)

---

*"You can't summit Everest by skipping base camps. You can't build enterprise cloud infrastructure by skipping governance. The physics of both are non-negotiable."*

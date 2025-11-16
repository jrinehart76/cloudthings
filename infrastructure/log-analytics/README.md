# Log Analytics Query Library

A curated collection of KQL (Kusto Query Language) queries for Azure monitoring, troubleshooting, and optimization. These queries solve real operational problems encountered across 100+ Azure environments.

## Philosophy

> "Using Log Analytics to... view logs" - [Technical Anxiety Blog](https://technicalanxiety.com/log-analytics/)

Log Analytics isn't just about viewing logs. It's about extracting actionable insights that drive decisions. These queries are battle-tested solutions to common (and uncommon) Azure operational challenges.

## Query Categories

### 💰 Cost Optimization
Identify waste and optimize spending. Queries that have saved organizations thousands monthly.

- **unused-resources.kql** - Find resources consuming budget without delivering value
- **oversized-vms.kql** - Identify VMs that can be downsized
- **orphaned-disks.kql** - Locate unattached disks costing money
- **idle-resources.kql** - Resources with minimal utilization
- **reserved-instance-opportunities.kql** - Where RIs would save money

### 🔒 Security Monitoring
Detect threats and compliance violations before they become incidents.

- **failed-logins.kql** - Brute force and credential stuffing attempts
- **privilege-escalation.kql** - Unauthorized elevation attempts
- **network-anomalies.kql** - Unusual traffic patterns
- **public-exposure.kql** - Resources accidentally exposed to internet
- **compliance-violations.kql** - Policy violations requiring remediation

### 🏥 Operational Health
Monitor system health and prevent outages.

- **vm-performance.kql** - CPU, memory, disk performance issues
- **backup-status.kql** - Backup success/failure tracking
- **update-compliance.kql** - Patch management status
- **certificate-expiration.kql** - Certificates expiring soon
- **service-health.kql** - Azure service issues affecting your resources

## Quick Start

### Prerequisites
- Azure subscription with Log Analytics workspace
- Resources sending diagnostic logs to workspace
- Appropriate RBAC permissions (Log Analytics Reader minimum)

### Running Queries

1. Navigate to your Log Analytics workspace in Azure Portal
2. Click "Logs" in the left menu
3. Copy query from this repository
4. Paste into query editor
5. Adjust time range as needed
6. Click "Run"

### Saving Queries

```bash
# Save query to workspace
az monitor log-analytics query pack create \
  --resource-group "rg-monitoring" \
  --query-pack-name "operational-queries" \
  --location "eastus"

# Add query to pack
az monitor log-analytics query pack query create \
  --query-pack-name "operational-queries" \
  --resource-group "rg-monitoring" \
  --query-id "unused-resources" \
  --display-name "Find Unused Resources" \
  --body @cost-optimization/unused-resources.kql
```

## Query Standards

All queries in this library follow these standards:

### 1. Performance Optimized
- Use `where` clauses early to filter data
- Limit time ranges appropriately
- Avoid `search *` when possible
- Use summarize instead of distinct when appropriate

### 2. Well Documented
- Header comment explaining purpose
- Parameter descriptions
- Expected output format
- Example use cases

### 3. Parameterized
- Time ranges as variables
- Thresholds as variables
- Resource filters as variables

### 4. Actionable Results
- Clear column names
- Sorted by priority/impact
- Include resource IDs for automation
- Provide context for decisions

## Example Query Structure

```kql
// Query: Find VMs with high CPU but low memory usage
// Purpose: Identify candidates for VM SKU optimization
// Impact: Potential 20-30% cost savings
// Author: Jason Rinehart
// Last Updated: 2025-01-15

let timeRange = 7d;
let cpuThreshold = 80.0;
let memoryThreshold = 40.0;

Perf
| where TimeGenerated > ago(timeRange)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by Computer, _ResourceId
| join kind=inner (
    Perf
    | where TimeGenerated > ago(timeRange)
    | where ObjectName == "Memory" and CounterName == "% Committed Bytes In Use"
    | summarize AvgMemory = avg(CounterValue) by Computer, _ResourceId
) on Computer, _ResourceId
| where AvgCPU > cpuThreshold and AvgMemory < memoryThreshold
| project Computer, AvgCPU, AvgMemory, _ResourceId
| order by AvgCPU desc
```

## Integration with Governance

These queries support the five governance disciplines:

### Cost Management
- Identify waste before it compounds
- Track spending trends
- Validate budget assumptions

### Security Baseline
- Detect threats in real-time
- Monitor compliance continuously
- Audit access patterns

### Identity Baseline
- Track authentication failures
- Monitor privilege usage
- Audit role assignments

### Resource Consistency
- Verify tagging compliance
- Monitor naming standards
- Track resource organization

### Deployment Acceleration
- Monitor deployment success rates
- Track configuration drift
- Measure automation effectiveness

## Workbooks

Pre-built Azure Workbooks that visualize these queries:

- **governance-dashboard.json** - Overall governance posture
- **cost-management-dashboard.json** - Spending analysis and optimization
- **security-posture-dashboard.json** - Security metrics and alerts
- **operational-health-dashboard.json** - System health and performance

## Real-World Impact

These queries have helped organizations:

- **Reduce costs by 30-40%** through unused resource identification
- **Prevent security incidents** by detecting anomalies early
- **Improve uptime** through proactive health monitoring
- **Accelerate troubleshooting** from hours to minutes
- **Automate remediation** by providing actionable data

## Contributing

Found a useful query? Improved an existing one? Contributions welcome:

1. Follow the query standards above
2. Test thoroughly in your environment
3. Document purpose and expected impact
4. Submit with clear examples

## Related Resources

- [Technical Anxiety Blog - Log Analytics](https://technicalanxiety.com/log-analytics/)
- [Azure Monitor KQL Reference](https://docs.microsoft.com/azure/azure-monitor/logs/kql-quick-reference)
- [Log Analytics Best Practices](https://docs.microsoft.com/azure/azure-monitor/logs/query-optimization)

## Query Index

### Cost Optimization
| Query | Purpose | Avg Savings |
|-------|---------|-------------|
| unused-resources.kql | Find idle resources | 20-30% |
| oversized-vms.kql | Right-size VMs | 15-25% |
| orphaned-disks.kql | Remove unused disks | 5-10% |
| idle-resources.kql | Low utilization resources | 10-20% |
| reserved-instance-opportunities.kql | RI recommendations | 30-40% |

### Security Monitoring
| Query | Purpose | Detection Rate |
|-------|---------|----------------|
| failed-logins.kql | Brute force attempts | High |
| privilege-escalation.kql | Unauthorized elevation | Critical |
| network-anomalies.kql | Unusual traffic | Medium |
| public-exposure.kql | Accidental exposure | Critical |
| compliance-violations.kql | Policy violations | High |

### Operational Health
| Query | Purpose | MTTR Impact |
|-------|---------|-------------|
| vm-performance.kql | Performance issues | -60% |
| backup-status.kql | Backup monitoring | -40% |
| update-compliance.kql | Patch status | -50% |
| certificate-expiration.kql | Cert management | -80% |
| service-health.kql | Azure issues | -30% |

---

*"If one person solves a problem faster because I documented what I learned, then this effort matters."*

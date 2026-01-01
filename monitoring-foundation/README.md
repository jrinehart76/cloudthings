# Monitoring Foundation

Reference implementation for the [Beyond Azure Monitor](https://technicalanxiety.com/beyond-azure-monitor-pt1) series. Deploys context-aware, intelligent monitoring with dynamic baselines and predictive alerting.

## What This Deploys

- **Log Analytics Workspace** with optimized retention and saved KQL searches
- **Action Groups** for alert routing (email, webhook/ITSM)
- **Intelligent Alert Rules**:
  - Context-aware CPU monitoring (business hours aware)
  - Dynamic baseline response time alerts
  - Capacity prediction (7-day forecast)
  - Error rate anomaly detection
- **Operational Workbook** for NOC/Operations visibility

## Quick Start

```bash
# Clone the repo
git clone https://github.com/jrinehart76/cloudthings.git
cd cloudthings/monitoring-foundation

# Deploy to dev environment
az deployment group create \
  --resource-group rg-monitoring-dev \
  --template-file main.bicep \
  --parameters environment=dev alertEmailAddresses='["you@company.com"]'

# Deploy to production with ITSM integration
az deployment group create \
  --resource-group rg-monitoring-prod \
  --template-file main.bicep \
  --parameters @examples/parameters.prod.json
```

Or use the PowerShell script for more control:

```powershell
.\scripts\Deploy-MonitoringFoundation.ps1 `
  -SubscriptionId "your-subscription-id" `
  -ResourceGroupName "rg-monitoring" `
  -Environment "prod" `
  -AlertEmailAddresses @("oncall@company.com", "platform@company.com") `
  -ItsmWebhookUrl "https://your-servicenow-instance.service-now.com/api/..."
```

## Repository Structure

```
monitoring-foundation/
├── main.bicep                              # Main orchestration template
├── modules/
│   ├── log-analytics.bicep                 # Workspace + saved searches
│   ├── action-groups.bicep                 # Notification routing
│   ├── alert-rules.bicep                   # Intelligent alert rules
│   └── workbooks.bicep                     # Operational dashboards
├── workbook-templates/
│   └── operational-overview.json           # NOC workbook definition
├── queries/
│   ├── context-aware-cpu.kql               # Part 1 patterns
│   ├── dynamic-baseline.kql                # Part 1 patterns
│   ├── service-correlation.kql             # Part 2 patterns
│   ├── anomaly-detection.kql               # Part 2 patterns
│   └── capacity-prediction.kql             # Part 2 patterns
├── scripts/
│   └── Deploy-MonitoringFoundation.ps1     # Deployment automation
└── examples/
    ├── parameters.dev.json
    ├── parameters.staging.json
    └── parameters.prod.json
```

## Environment-Specific Thresholds

The deployment automatically adjusts thresholds based on environment:

| Metric | Dev | Staging | Prod |
|--------|-----|---------|------|
| CPU Warning | 90% | 85% | 75% |
| CPU Critical | 95% | 92% | 85% |
| Memory Warning | 90% | 85% | 80% |
| Memory Critical | 95% | 92% | 90% |
| Response Time Multiplier | 3x | 2.5x | 2x |
| Error Rate Threshold | 10% | 5% | 2% |

## Customization

### Adjusting Business Hours

Edit the `businessHours` datatable in `modules/alert-rules.bicep`:

```kql
let businessHours = datatable(['Day of Week']:int, ['Start Hour']:int, ['End Hour']:int) [
    1, 8, 18,  // Monday 8am-6pm
    2, 8, 18,  // Tuesday
    // ... add your hours
];
```

### ITSM Integration

The action group accepts a webhook URL for ITSM integration. The webhook receives the [Common Alert Schema](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-common-schema) payload.

For ServiceNow, create an inbound REST API endpoint that:
1. Receives the alert payload
2. Maps fields to your incident template
3. Creates/updates incidents based on alert state

For PagerDuty, use their [Events API v2](https://developer.pagerduty.com/docs/events-api-v2/overview/) endpoint.

### Adding Custom Alert Rules

Add new rules to `modules/alert-rules.bicep` following the existing patterns. Tag with:
- `alertType`: infrastructure, application, capacity
- `pattern`: context-aware, dynamic-baseline, predictive, anomaly-detection
- `automationEligible`: true/false for self-healing workflows

## Prerequisites

- Azure CLI or Azure PowerShell
- Contributor role on target subscription
- Resource group (script creates if missing)

## Related Content

- [Beyond Azure Monitor Part 1: The Reality of Enterprise Monitoring](https://technicalanxiety.com/beyond-azure-monitor-pt1)
- [Beyond Azure Monitor Part 2: Advanced KQL Patterns](https://technicalanxiety.com/beyond-azure-monitor-pt2)
- [Beyond Azure Monitor Part 3: Production-Ready Monitoring](https://technicalanxiety.com/beyond-azure-monitor-pt3)
- [KQL for Infrastructure Teams](https://technicalanxiety.com/kql-for-infrastructure-teams)
- [Azure Workbooks: Custom Dashboards That Don't Suck](https://technicalanxiety.com/azure-workbooks-custom-dashboards)

## License

MIT. Use it, adapt it, make it yours.

## Contributing

Issues and PRs welcome. This is reference code - if you find improvements, share them.

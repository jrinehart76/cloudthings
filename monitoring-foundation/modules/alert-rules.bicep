// Alert Rules Module
// Deploys context-aware, intelligent alert rules from the Beyond Azure Monitor series
// These alerts understand business hours, use dynamic baselines, and reduce noise

@description('Azure region')
param location string

@description('Log Analytics workspace resource ID')
param workspaceId string

@description('Action group resource ID for notifications')
param actionGroupId string

@description('Environment identifier')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Environment-specific thresholds')
param thresholds object

@description('Resource tags')
param tags object = {}

// Severity mapping based on environment
var severityMap = {
  dev: { warning: 3, critical: 2 }
  staging: { warning: 2, critical: 1 }
  prod: { warning: 1, critical: 0 }
}

var severity = severityMap[environment]

// ============================================================================
// CONTEXT-AWARE CPU MONITORING
// From Part 1: Understands business hours, adjusts thresholds accordingly
// ============================================================================

resource cpuAlertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-cpu-context-aware-${environment}'
  location: location
  tags: union(tags, {
    alertType: 'infrastructure'
    pattern: 'context-aware'
  })
  properties: {
    displayName: 'Context-Aware CPU Monitoring - ${toUpper(environment)}'
    description: 'Alerts on sustained high CPU with business hours awareness. Thresholds adjust based on time of day.'
    severity: severity.warning
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [workspaceId]
    criteria: {
      allOf: [
        {
          query: '''
let businessHours = datatable(['Day of Week']:int, ['Start Hour']:int, ['End Hour']:int) [
    1, 8, 18, 2, 8, 18, 3, 8, 18, 4, 8, 18, 5, 8, 18
];
Perf
| where TimeGenerated > ago(15m)
| where ObjectName has 'processor'
    and CounterName has 'processor time'
    and InstanceName has 'total'
| extend ['Day of Week'] = toint(dayofweek(TimeGenerated) / 1d)
| extend ['Current Hour'] = hourofday(TimeGenerated)
| join kind=leftouter businessHours on ['Day of Week']
| extend ['Is Business Hours'] = (['Current Hour'] >= ['Start Hour'] and ['Current Hour'] <= ['End Hour'])
| extend ['CPU Threshold'] = iff(['Is Business Hours'], ${thresholds.cpuWarning}.0, ${thresholds.cpuCritical}.0)
| where CounterValue > ['CPU Threshold']
| summarize
    ['Average CPU'] = avg(CounterValue),
    ['Max CPU'] = max(CounterValue),
    ['Sample Count'] = count()
    by Computer, bin(TimeGenerated, 5m)
| where ['Sample Count'] >= 3
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 3
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [actionGroupId]
      customProperties: {
        environment: environment
        alertCategory: 'infrastructure'
        automationEligible: 'false'
      }
    }
  }
}

// ============================================================================
// DYNAMIC BASELINE RESPONSE TIME
// From Part 1: Compares current performance against historical patterns
// ============================================================================

resource responseTimeAlertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-response-time-baseline-${environment}'
  location: location
  tags: union(tags, {
    alertType: 'application'
    pattern: 'dynamic-baseline'
  })
  properties: {
    displayName: 'Dynamic Baseline Response Time - ${toUpper(environment)}'
    description: 'Alerts when response times exceed dynamic baseline calculated from 14-day historical patterns.'
    severity: severity.warning
    enabled: true
    evaluationFrequency: 'PT10M'
    windowSize: 'PT1H'
    scopes: [workspaceId]
    criteria: {
      allOf: [
        {
          query: '''
let sensitivityFactor = ${thresholds.responseTimeMultiplier};
let historicalPattern = AppRequests
| where TimeGenerated between (ago(14d) .. ago(1h))
| extend ['Hour of Day'] = hourofday(TimeGenerated)
| summarize
    ['Baseline Mean'] = avg(DurationMs),
    ['Baseline StdDev'] = stdev(DurationMs)
    by Name, ['Hour of Day']
| where ['Baseline Mean'] > 0;
let currentPerformance = AppRequests
| where TimeGenerated > ago(1h)
| extend ['Hour of Day'] = hourofday(TimeGenerated)
| summarize ['Current Mean'] = avg(DurationMs), ['Request Count'] = count() by Name, ['Hour of Day'];
historicalPattern
| join kind=inner currentPerformance on Name, ['Hour of Day']
| extend ['Anomaly Threshold'] = ['Baseline Mean'] + (sensitivityFactor * ['Baseline StdDev'])
| where ['Current Mean'] > ['Anomaly Threshold']
| where ['Request Count'] > 10
| extend ['Severity Score'] = (['Current Mean'] - ['Baseline Mean']) / ['Baseline StdDev']
| where ['Severity Score'] > 2.0
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [actionGroupId]
      customProperties: {
        environment: environment
        alertCategory: 'application'
        automationEligible: 'false'
      }
    }
  }
}

// ============================================================================
// CAPACITY PREDICTION
// From Part 2: Alerts on resources projected to hit capacity within 7 days
// ============================================================================

resource capacityPredictionAlertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-capacity-prediction-${environment}'
  location: location
  tags: union(tags, {
    alertType: 'capacity'
    pattern: 'predictive'
  })
  properties: {
    displayName: 'Capacity Prediction Alert - ${toUpper(environment)}'
    description: 'Proactive alert for resources projected to exceed 85% capacity within 7 days based on trend analysis.'
    severity: severity.warning
    enabled: true
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    scopes: [workspaceId]
    criteria: {
      allOf: [
        {
          query: '''
let trendPeriod = 14d;
let forecastDays = 7;
let capacityThreshold = 85.0;
Perf
| where TimeGenerated > ago(trendPeriod)
| where ObjectName == 'Memory' and CounterName == '% Committed Bytes In Use'
| summarize ['Daily Avg'] = avg(CounterValue) by Computer, ['Day'] = startofday(TimeGenerated)
| order by Computer, ['Day'] asc
| serialize
| extend ['Row Number'] = row_number(1, prev(Computer) != Computer)
| extend ['Previous Value'] = prev(['Daily Avg'], 1, ['Daily Avg'])
| extend ['Daily Change'] = ['Daily Avg'] - ['Previous Value']
| summarize
    ['Current Usage'] = max(['Daily Avg']),
    ['Avg Daily Growth'] = avg(['Daily Change']),
    ['Data Points'] = count()
    by Computer
| where ['Data Points'] >= 7
| where ['Avg Daily Growth'] > 0
| extend ['Days to Threshold'] = (capacityThreshold - ['Current Usage']) / ['Avg Daily Growth']
| where ['Days to Threshold'] > 0 and ['Days to Threshold'] <= forecastDays
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [actionGroupId]
      customProperties: {
        environment: environment
        alertCategory: 'capacity'
        automationEligible: 'true'
      }
    }
  }
}

// ============================================================================
// ERROR RATE ANOMALY
// From Part 2: Detects error rate spikes against rolling baseline
// ============================================================================

resource errorRateAlertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-error-rate-anomaly-${environment}'
  location: location
  tags: union(tags, {
    alertType: 'application'
    pattern: 'anomaly-detection'
  })
  properties: {
    displayName: 'Error Rate Anomaly Detection - ${toUpper(environment)}'
    description: 'Alerts when error rates spike above baseline. Uses statistical analysis to reduce false positives.'
    severity: severity.critical
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [workspaceId]
    criteria: {
      allOf: [
        {
          query: '''
let errorThreshold = ${thresholds.errorRatePercent};
let baselineWindow = 7d;
let currentWindow = 15m;
let baseline = AppRequests
| where TimeGenerated between (ago(baselineWindow) .. ago(currentWindow))
| summarize
    ['Baseline Total'] = count(),
    ['Baseline Errors'] = countif(Success == false)
    by Name
| extend ['Baseline Error Rate'] = round(100.0 * ['Baseline Errors'] / ['Baseline Total'], 2);
let current = AppRequests
| where TimeGenerated > ago(currentWindow)
| summarize
    ['Current Total'] = count(),
    ['Current Errors'] = countif(Success == false)
    by Name
| extend ['Current Error Rate'] = round(100.0 * ['Current Errors'] / ['Current Total'], 2);
baseline
| join kind=inner current on Name
| where ['Current Total'] > 10
| extend ['Error Rate Change'] = ['Current Error Rate'] - ['Baseline Error Rate']
| where ['Current Error Rate'] > errorThreshold
| where ['Error Rate Change'] > 2.0
| project
    Name,
    ['Current Error Rate'],
    ['Baseline Error Rate'],
    ['Error Rate Change'],
    ['Current Errors'],
    ['Current Total']
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [actionGroupId]
      customProperties: {
        environment: environment
        alertCategory: 'application'
        automationEligible: 'false'
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output alertRuleNames array = [
  cpuAlertRule.name
  responseTimeAlertRule.name
  capacityPredictionAlertRule.name
  errorRateAlertRule.name
]

output alertRuleIds array = [
  cpuAlertRule.id
  responseTimeAlertRule.id
  capacityPredictionAlertRule.id
  errorRateAlertRule.id
]
// Log Analytics Workspace Module
// Configures workspace with appropriate retention and pricing tier

@description('Name for the Log Analytics workspace')
param workspaceName string

@description('Azure region')
param location string

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionDays int = 90

@description('Resource tags')
param tags object = {}

// Pricing tier selection based on expected ingestion
// PerGB2018 is appropriate for most workloads
// Consider CapacityReservation for 100+ GB/day
var sku = 'PerGB2018'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1 // No cap - adjust for cost control if needed
    }
  }
}

// Saved searches for the KQL patterns from the series
// These become reusable building blocks for alerts and workbooks

resource contextAwareCpuSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'ContextAwareCPU'
  properties: {
    category: 'Monitoring Foundation'
    displayName: 'Context-Aware CPU Monitoring'
    query: '''
let businessHours = datatable(['Day of Week']:int, ['Start Hour']:int, ['End Hour']:int) [
    1, 8, 18,  // Monday
    2, 8, 18,  // Tuesday
    3, 8, 18,  // Wednesday
    4, 8, 18,  // Thursday
    5, 8, 18   // Friday
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
| extend ['CPU Threshold'] = iff(['Is Business Hours'], 70.0, 85.0)
| where CounterValue > ['CPU Threshold']
| summarize
    ['Average CPU'] = avg(CounterValue),
    ['Max CPU'] = max(CounterValue),
    ['Sample Count'] = count()
    by Computer, bin(TimeGenerated, 5m)
| where ['Sample Count'] >= 3
'''
    version: 2
  }
}

resource dynamicBaselineSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'DynamicBaselinePerformance'
  properties: {
    category: 'Monitoring Foundation'
    displayName: 'Dynamic Baseline Performance Analysis'
    query: '''
let lookbackPeriod = 14d;
let currentWindow = 1h;
let historicalPattern = AppRequests
| where TimeGenerated between (ago(lookbackPeriod) .. ago(currentWindow))
| extend ['Hour of Day'] = hourofday(TimeGenerated)
| extend ['Day of Week'] = toint(dayofweek(TimeGenerated) / 1d)
| summarize
    ['Baseline Mean'] = avg(DurationMs),
    ['Baseline StdDev'] = stdev(DurationMs),
    ['Baseline P95'] = percentile(DurationMs, 95)
    by Name, ['Hour of Day'], ['Day of Week']
| where ['Baseline Mean'] > 0;
let currentPerformance = AppRequests
| where TimeGenerated > ago(currentWindow)
| extend ['Hour of Day'] = hourofday(TimeGenerated)
| extend ['Day of Week'] = toint(dayofweek(TimeGenerated) / 1d)
| summarize
    ['Current Mean'] = avg(DurationMs),
    ['Current P95'] = percentile(DurationMs, 95),
    ['Request Count'] = count()
    by Name, ['Hour of Day'], ['Day of Week'];
historicalPattern
| join kind=inner currentPerformance on Name, ['Hour of Day'], ['Day of Week']
| extend ['Performance Ratio'] = ['Current Mean'] / ['Baseline Mean']
| extend ['Deviation Score'] = (['Current Mean'] - ['Baseline Mean']) / ['Baseline StdDev']
| where ['Request Count'] > 10
| project
    Name,
    ['Current Mean'],
    ['Baseline Mean'],
    ['Performance Ratio'],
    ['Deviation Score'],
    ['Request Count']
| order by ['Deviation Score'] desc
'''
    version: 2
  }
}

resource capacityPredictionSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'CapacityPrediction'
  properties: {
    category: 'Monitoring Foundation'
    displayName: 'Capacity Trend Prediction'
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
| where ['Data Points'] >= 7  // Need at least a week of data
| where ['Avg Daily Growth'] > 0  // Only growing resources
| extend ['Days to Threshold'] = (capacityThreshold - ['Current Usage']) / ['Avg Daily Growth']
| where ['Days to Threshold'] > 0 and ['Days to Threshold'] <= forecastDays
| extend ['Projected Date'] = format_datetime(datetime_add('day', toint(['Days to Threshold']), now()), 'yyyy-MM-dd')
| project
    Computer,
    ['Current Usage'] = round(['Current Usage'], 1),
    ['Daily Growth Rate'] = round(['Avg Daily Growth'], 2),
    ['Days Until 85%'] = round(['Days to Threshold'], 1),
    ['Projected Date']
| order by ['Days Until 85%'] asc
'''
    version: 2
  }
}

resource serviceCorrelationSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'ServiceCorrelation'
  properties: {
    category: 'Monitoring Foundation'
    displayName: 'Cross-Service Error Correlation'
    query: '''
let timeWindow = 1h;
let correlationThreshold = 0.7;
let appErrors = AppExceptions
| where TimeGenerated > ago(timeWindow)
| summarize ['App Errors'] = count() by bin(TimeGenerated, 5m), ['Service'] = AppRoleName;
let infraEvents = Perf
| where TimeGenerated > ago(timeWindow)
| where ObjectName has 'processor' and CounterName has 'processor time'
| where CounterValue > 80
| summarize ['High CPU Events'] = count() by bin(TimeGenerated, 5m), ['Service'] = Computer;
let dbLatency = AzureDiagnostics
| where TimeGenerated > ago(timeWindow)
| where ResourceType == 'SERVERS/DATABASES'
| where MetricName == 'cpu_percent' and Average > 70
| summarize ['DB Pressure Events'] = count() by bin(TimeGenerated, 5m), ['Service'] = Resource;
appErrors
| join kind=fullouter infraEvents on TimeGenerated
| join kind=fullouter dbLatency on TimeGenerated
| extend ['Correlation Window'] = TimeGenerated
| summarize
    ['Total App Errors'] = sum(['App Errors']),
    ['Total CPU Events'] = sum(['High CPU Events']),
    ['Total DB Events'] = sum(['DB Pressure Events'])
    by bin(['Correlation Window'], 15m)
| where ['Total App Errors'] > 0
| extend ['Infra Correlation'] = iff(['Total CPU Events'] > 0, 'CPU Pressure Detected', 'No CPU Issues')
| extend ['DB Correlation'] = iff(['Total DB Events'] > 0, 'Database Pressure Detected', 'No DB Issues')
| project
    ['Time Window'] = ['Correlation Window'],
    ['Application Errors'] = ['Total App Errors'],
    ['Infrastructure Status'] = ['Infra Correlation'],
    ['Database Status'] = ['DB Correlation']
| order by ['Time Window'] desc
'''
    version: 2
  }
}

// Outputs
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output workspaceCustomerId string = workspace.properties.customerId
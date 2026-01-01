// Monitoring Foundation - Main Orchestration
// Companion to the "Beyond Azure Monitor" series
// https://technicalanxiety.com/beyond-azure-monitor-pt1
//
// This template deploys a complete intelligent monitoring foundation:
// - Log Analytics workspace with optimized retention
// - Action groups for alert routing
// - Context-aware alert rules with dynamic thresholds
// - Operational workbooks
//
// Usage:
//   az deployment group create \
//     --resource-group rg-monitoring \
//     --template-file main.bicep \
//     --parameters @parameters.prod.json

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Environment identifier for resource naming and threshold selection')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name prefix for all resources')
@minLength(2)
@maxLength(10)
param namePrefix string = 'mon'

@description('Log Analytics retention in days')
@minValue(30)
@maxValue(730)
param retentionDays int = environment == 'prod' ? 90 : 30

@description('Email addresses for alert notifications')
param alertEmailAddresses array = []

@description('Webhook URL for ITSM integration (ServiceNow, etc.)')
param itsmWebhookUrl string = ''

@description('Enable self-healing automation runbooks')
param enableSelfHealing bool = false

@description('Tags applied to all resources')
param tags object = {
  environment: environment
  managedBy: 'monitoring-foundation'
  series: 'beyond-azure-monitor'
}

// ============================================================================
// VARIABLES
// ============================================================================

var resourceNames = {
  workspace: '${namePrefix}-law-${environment}-${uniqueString(resourceGroup().id)}'
  actionGroup: '${namePrefix}-ag-${environment}'
  workbook: '${namePrefix}-wb-ops-${environment}'
}

// Environment-specific thresholds
// Adjust these based on your SLAs and operational tolerance
var alertThresholds = {
  dev: {
    cpuWarning: 90
    cpuCritical: 95
    memoryWarning: 90
    memoryCritical: 95
    responseTimeMultiplier: 3
    errorRatePercent: 10
  }
  staging: {
    cpuWarning: 85
    cpuCritical: 92
    memoryWarning: 85
    memoryCritical: 92
    responseTimeMultiplier: 2.5
    errorRatePercent: 5
  }
  prod: {
    cpuWarning: 75
    cpuCritical: 85
    memoryWarning: 80
    memoryCritical: 90
    responseTimeMultiplier: 2
    errorRatePercent: 2
  }
}

var thresholds = alertThresholds[environment]

// ============================================================================
// MODULES
// ============================================================================

module workspace 'modules/log-analytics.bicep' = {
  name: 'deploy-workspace'
  params: {
    workspaceName: resourceNames.workspace
    location: location
    retentionDays: retentionDays
    tags: tags
  }
}

module actionGroups 'modules/action-groups.bicep' = {
  name: 'deploy-action-groups'
  params: {
    actionGroupName: resourceNames.actionGroup
    emailAddresses: alertEmailAddresses
    itsmWebhookUrl: itsmWebhookUrl
    tags: tags
  }
}

module alertRules 'modules/alert-rules.bicep' = {
  name: 'deploy-alert-rules'
  params: {
    location: location
    workspaceId: workspace.outputs.workspaceId
    actionGroupId: actionGroups.outputs.actionGroupId
    environment: environment
    thresholds: thresholds
    tags: tags
  }
}

module workbooks 'modules/workbooks.bicep' = {
  name: 'deploy-workbooks'
  params: {
    workbookName: resourceNames.workbook
    location: location
    workspaceId: workspace.outputs.workspaceId
    tags: tags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Log Analytics workspace resource ID')
output workspaceId string = workspace.outputs.workspaceId

@description('Log Analytics workspace name')
output workspaceName string = workspace.outputs.workspaceName

@description('Action group resource ID')
output actionGroupId string = actionGroups.outputs.actionGroupId

@description('Deployed alert rule names')
output alertRuleNames array = alertRules.outputs.alertRuleNames

@description('Workbook resource ID')
output workbookId string = workbooks.outputs.workbookId
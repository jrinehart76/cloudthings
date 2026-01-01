// Workbooks Module
// Deploys operational dashboards that surface actionable information
// Based on patterns from the Azure Workbooks post

@description('Name for the workbook')
param workbookName string

@description('Azure region')
param location string

@description('Log Analytics workspace resource ID')
param workspaceId string

@description('Resource tags')
param tags object = {}

var workbookId = guid(workbookName, resourceGroup().id)

// Operational Overview Workbook
// Designed for NOC/Operations teams - surfaces what needs attention
resource operationalWorkbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookId
  location: location
  tags: union(tags, {
    'hidden-title': 'Operational Overview'
  })
  kind: 'shared'
  properties: {
    displayName: 'Operational Overview'
    serializedData: string(loadJsonContent('../workbook-templates/operational-overview.json'))
    version: '1.0'
    sourceId: workspaceId
    category: 'workbook'
  }
}

output workbookId string = operationalWorkbook.id
output workbookName string = operationalWorkbook.name
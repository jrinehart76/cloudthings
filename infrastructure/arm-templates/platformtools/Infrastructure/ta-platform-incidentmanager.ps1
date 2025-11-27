<#
.SYNOPSIS
    Deploys Incident Manager Logic Apps for critical alert processing.

.DESCRIPTION
    This script deploys Incident Manager Logic Apps that handle critical severity
    alerts and create incidents in Dynamics CRM. The Incident Managers process:
    
    1. Exception Incidents: Critical exceptions and errors requiring immediate action
    2. Critical Incidents: Sev1 critical alerts for infrastructure and applications
    
    These Logic Apps provide:
    - Immediate incident creation for critical alerts
    - Integration with Dynamics CRM for incident tracking
    - Automated notification and escalation workflows
    - Critical alert processing separate from lower severity events
    
    Incident Managers are designed for the highest priority alerts that require
    immediate attention and tracking through the incident management system.

.PARAMETER logicAppEnv
    The environment for deployment (e.g., 'Dev', 'Prod', 'Test').
    Used for naming and configuration differentiation.

.PARAMETER logicAppLocation
    The Azure region where the Logic Apps will be deployed.
    Example: 'eastus', 'westus2'

.PARAMETER dynamicsCrmOnlineConnectionName
    The name of the Dynamics CRM Web API connection.
    This connection enables Logic Apps to create incidents in Dynamics.
    Must be pre-deployed or will be created during deployment.

.PARAMETER resourceGroup
    The resource group where the Logic Apps will be deployed.
    Example: 'rg-platform-prod'

.EXAMPLE
    .\ta-platform-incidentmanager.ps1 -logicAppEnv 'Prod' -logicAppLocation 'eastus' -dynamicsCrmOnlineConnectionName 'dynamics-crm-connection' -resourceGroup 'rg-platform-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Dynamics CRM instance must be configured
    - Dynamics CRM API connection should be pre-deployed
    - User must have Contributor role on the resource group
    - ARM template files must exist in ./templates/alertmanager/:
      * alertmanager-incidents.json
      * alertmanager-critical.json
    
    Post-Deployment:
    - Configure critical action groups to trigger these Logic Apps
    - Authorize the Dynamics CRM connection if needed
    - Test incident creation for critical alerts
    - Configure escalation policies in Dynamics CRM
    
    Related Scripts:
    - ta-platform-eventmanager.ps1: Deploys event managers for lower severity alerts
    - ta-platform-actiongroups.ps1: Deploys action groups that trigger these Logic Apps
    
    Impact: Enables automated incident creation and tracking for critical platform alerts.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Environment for deployment (Dev, Prod, Test)")]
    [ValidateNotNullOrEmpty()]
    [string]$logicAppEnv,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the Logic Apps")]
    [ValidateNotNullOrEmpty()]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true, HelpMessage="Name of the Dynamics CRM Web API connection")]
    [ValidateNotNullOrEmpty()]
    [string]$dynamicsCrmOnlineConnectionName,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Incident Manager Logic Apps"
Write-Output "=========================================="
Write-Output "Environment: $logicAppEnv"
Write-Output "Resource Group: $resourceGroup"
Write-Output "Location: $logicAppLocation"
Write-Output ""

Try {
    # Deploy Exception Incident Manager
    # Handles critical exceptions and errors requiring immediate action
    Write-Output "Deploying Exception Incident Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-incident-managers-exceptions" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/alertmanager/alertmanager-incidents.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Exception Incident Manager deployed"
    
    # Deploy Critical Incident Manager
    # Handles Sev1 critical alerts for infrastructure and applications
    Write-Output "Deploying Critical Incident Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-incident-managers-criticals" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/alertmanager/alertmanager-critical.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Critical Incident Manager deployed"
    
    Write-Output ""
    Write-Output "✓ All Incident Managers deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Incident Managers: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
<#
.SYNOPSIS
    Deploys Azure resource and service health monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for Azure platform health monitoring:
    
    Resource Health Alerts:
    - Individual resource health status changes
    - Resource availability issues
    - Platform-initiated maintenance events
    
    Service Health Alerts:
    - Azure service outages
    - Planned maintenance notifications
    - Service degradation events
    - Regional service issues
    
    These alerts are essential for:
    - Proactive awareness of Azure platform issues
    - Distinguishing application issues from platform issues
    - Planning for maintenance windows
    - Meeting SLA tracking requirements
    
    The script deploys ARM templates that create activity log alerts in Azure Monitor.

.PARAMETER agResourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.

.EXAMPLE
    .\ta-alerts-resources.ps1 -agResourceGroup 'rg-monitoring-prod' -subscriptionId '12345678-1234-1234-1234-123456789012'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Action group MSP-alert-servicehealth must be pre-deployed
    - User must have Contributor or Monitoring Contributor role
    - ARM template files must be in the same directory:
      * alert.critical.resourcehealth.json
      * alert.critical.servicehealth.json
    
    Alert Types:
    - Resource Health: Monitors individual resource availability
    - Service Health: Monitors Azure service-level events
    
    Impact: Provides critical visibility into Azure platform health, enabling
    teams to distinguish between application issues and platform issues, and
    plan appropriately for maintenance events.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId
)

Write-Output "=========================================="
Write-Output "Deploy Azure Health Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Subscription: $subscriptionId"
Write-Output ""

$actionGroupSvcId = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-servicehealth"

Write-Output "Deploying resource health alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-resourcehealth-critical-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.resourcehealth.json `
        -alertNameResource "MSP-azure-resource-alert" `
        -actionGroupId $actionGroupSvcId `
        -ErrorAction Stop
    
    Write-Output "✓ Resource health alerts deployed"
}
Catch {
    Write-Error "Failed to deploy resource health alerts: $_"
    throw
}

Write-Output "Deploying service health alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-servicehealth-critical-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.servicehealth.json `
        -alertNameService "MSP-azure-service-alert" `
        -actionGroupId $actionGroupSvcId `
        -ErrorAction Stop
    
    Write-Output "✓ Service health alerts deployed"
}
Catch {
    Write-Error "Failed to deploy service health alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 2 alert rules:"
Write-Output "  - Resource Health (individual resource availability)"
Write-Output "  - Service Health (Azure platform events)"
Write-Output "=========================================="
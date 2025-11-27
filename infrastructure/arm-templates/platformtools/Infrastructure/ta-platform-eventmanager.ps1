<#
.SYNOPSIS
    Deploys Event Manager Logic Apps for alert processing and incident creation.

.DESCRIPTION
    This script deploys multiple Event Manager Logic Apps that process Azure Monitor
    alerts and create incidents in Dynamics CRM. The Event Managers handle different
    severity levels and event types:
    
    - Sev2 Events: Critical exceptions requiring immediate attention
    - Sev3 Events: Important exceptions needing timely response
    - Sev4 Events: Warning-level events for awareness
    - Info Events: Informational events for tracking
    - Security Events: Security-related alerts and findings
    - Azure Events: Azure service health and resource health events
    - Web Events: Application and web service alerts
    
    Each Event Manager:
    - Receives alerts from Azure Monitor action groups
    - Processes and enriches alert data
    - Creates incidents in Dynamics CRM
    - Links incidents to customer accounts
    - Assigns monitoring contacts
    
    This is a core component of the platform's incident management system.

.PARAMETER logicAppEnv
    The environment for deployment (e.g., 'Dev', 'Prod', 'Test').
    Used for naming and configuration differentiation.

.PARAMETER logicAppLocation
    The Azure region where the Logic Apps will be deployed.
    Example: 'eastus', 'westus2'

.PARAMETER dynamicsCrmOnlineConnectionName
    The name of the Dynamics CRM Web API connection.
    This connection enables Logic Apps to create incidents in Dynamics.
    If it doesn't exist, it will be created during deployment.

.PARAMETER resourceGroup
    The resource group where the Logic Apps will be deployed.
    Example: 'rg-platform-prod'

.PARAMETER accountGUID
    The GUID of the customer account in Dynamics CRM.
    Incidents will be linked to this account.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER monitoringGUID
    The GUID of the monitoring contact in Dynamics CRM.
    This contact will be assigned to created incidents.
    Format: GUID

.PARAMETER integrationAccountName
    The name of the Integration Account to use for B2B/EDI capabilities.
    If it doesn't exist, it will be created during deployment.

.PARAMETER deploymentVersion
    Version identifier for the deployment (e.g., '0125' for January 2025).
    Format: Two-digit month + two-digit year (MMYY)

.EXAMPLE
    .\ta-platform-eventmanager.ps1 -logicAppEnv 'Prod' -logicAppLocation 'eastus' -dynamicsCrmOnlineConnectionName 'dynamics-crm-connection' -resourceGroup 'rg-platform-prod' -accountGUID '12345678-1234-1234-1234-123456789012' -monitoringGUID '87654321-4321-4321-4321-210987654321' -integrationAccountName 'ia-platform-prod' -deploymentVersion '0125'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Contributors: dnite
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Dynamics CRM instance must be configured
    - User must have Contributor role on the resource group
    - ARM template files must exist in ./AlertManager/:
      * alertmanager-sev2events.json
      * alertmanager-sev3events.json
      * alertmanager-sev4events.json
      * alertmanager-infoevents.json
      * alertmanager-securityevents.json
      * alertmanager-azureevents.json
      * alertmanager-webevents.json
    
    Post-Deployment:
    - Configure action groups to trigger these Logic Apps
    - Authorize the Dynamics CRM connection if needed
    - Test incident creation for each severity level
    
    Related Scripts:
    - ta-platform-incidentmanager.ps1: Deploys critical incident managers
    - ta-platform-actiongroups.ps1: Deploys action groups that trigger these Logic Apps
    
    Impact: Enables automated incident creation and tracking for all platform alerts.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-06 - Initial version (jrinehart, dnite)
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
    [string]$resourceGroup,
    
    [Parameter(Mandatory=$true, HelpMessage="GUID of the customer account in Dynamics CRM")]
    [ValidateNotNullOrEmpty()]
    [string]$accountGUID,
    
    [Parameter(Mandatory=$true, HelpMessage="GUID of the monitoring contact in Dynamics CRM")]
    [ValidateNotNullOrEmpty()]
    [string]$monitoringGUID,

    [Parameter(Mandatory=$true, HelpMessage="Name of the Integration Account")]
    [ValidateNotNullOrEmpty()]
    [string]$integrationAccountName,

    [Parameter(Mandatory=$true, HelpMessage="Deployment version (MMYY format)")]
    [ValidateNotNullOrEmpty()]
    [string]$deploymentVersion
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Event Manager Logic Apps"
Write-Output "=========================================="
Write-Output "Environment: $logicAppEnv"
Write-Output "Resource Group: $resourceGroup"
Write-Output "Location: $logicAppLocation"
Write-Output "Deployment Version: $deploymentVersion"
Write-Output ""

Try {
    # Deploy Sev2 Event Manager
    # Handles critical exceptions requiring immediate attention
    Write-Output "Deploying Sev2 Event Manager..."
    New-AzResourceGroupDeployment `
    -Name "deploy-PLATFORM-sev2-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-sev2events.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
    -ErrorAction Stop
    Write-Output "✓ Sev2 Event Manager deployed"
    
    # Deploy Sev3 Event Manager
    # Handles important exceptions needing timely response
    Write-Output "Deploying Sev3 Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-sev3-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-sev3events.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Sev3 Event Manager deployed"
    
    # Deploy Sev4 Event Manager
    # Handles warning-level events for awareness
    Write-Output "Deploying Sev4 Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-sev4-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-sev4events.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Sev4 Event Manager deployed"
    
    # Deploy Info Event Manager
    # Handles informational events for tracking
    Write-Output "Deploying Info Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-info-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-infoevents.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Info Event Manager deployed"
    
    # Deploy Security Event Manager
    # Handles security-related alerts and findings
    Write-Output "Deploying Security Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-security-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-securityevents.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Security Event Manager deployed"
    
    # Deploy Azure Event Manager
    # Handles Azure service health and resource health events
    Write-Output "Deploying Azure Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-azure-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-azureevents.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Azure Event Manager deployed"
    
    # Deploy Web Event Manager
    # Handles application and web service alerts
    Write-Output "Deploying Web Event Manager..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-web-event-managers-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./AlertManager/alertmanager-webevents.json `
        -logicAppEnv $logicAppEnv `
        -logicAppLocation $logicAppLocation `
        -relatedAccountGUID $accountGUID `
        -monitoringContactGUID $monitoringGUID `
        -integrationAccountName $integrationAccountName `
        -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
        -ErrorAction Stop
    Write-Output "✓ Web Event Manager deployed"
    
    Write-Output ""
    Write-Output "✓ All Event Managers deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Event Managers: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
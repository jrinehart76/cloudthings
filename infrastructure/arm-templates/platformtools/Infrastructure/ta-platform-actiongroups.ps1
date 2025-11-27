<#
.SYNOPSIS
    Deploys Azure Monitor action groups for alert routing and notification.

.DESCRIPTION
    This script deploys all action groups required for the platform's alert management
    system. Action groups define how alerts are routed and processed based on severity:
    
    - Sev1 Critical (S1): Highest priority alerts requiring immediate response
    - Sev2 Critical/Exceptions (S2): Critical issues needing urgent attention
    - Sev3 Exceptions (S3): Important exceptions requiring timely response
    - Sev4 Warning/Info (S4): Lower priority warnings and informational alerts
    - Service Health: Azure service health and maintenance notifications
    - Web Alerts: Application and web service specific alerts
    - Security: High-severity security alerts and findings
    
    Each action group triggers Logic Apps that:
    - Process and enrich alert data
    - Create incidents in Dynamics CRM
    - Send notifications to appropriate teams
    - Execute automated remediation workflows
    
    This is the foundation of the platform's alert routing and incident management.

.PARAMETER resourceGroup
    The resource group where the action groups will be deployed.
    Example: 'rg-platform-prod'

.PARAMETER s2LogicAppId
    The resource ID of the Sev2 Event Manager Logic App.
    Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{name}

.PARAMETER s2LogicAppUrl
    The callback URL for the Sev2 Event Manager Logic App.
    This is the HTTP trigger URL that receives alert payloads.

.PARAMETER s3LogicAppId
    The resource ID of the Sev3 Event Manager Logic App.

.PARAMETER s3LogicAppUrl
    The callback URL for the Sev3 Event Manager Logic App.

.PARAMETER s4LogicAppId
    The resource ID of the Sev4 Event Manager Logic App.

.PARAMETER s4LogicAppUrl
    The callback URL for the Sev4 Event Manager Logic App.

.PARAMETER infoLogicAppId
    The resource ID of the Info Event Manager Logic App.

.PARAMETER infoLogicAppUrl
    The callback URL for the Info Event Manager Logic App.

.PARAMETER azureLogicAppId
    The resource ID of the Azure Service Health Event Manager Logic App.

.PARAMETER azureLogicAppUrl
    The callback URL for the Azure Service Health Event Manager Logic App.

.PARAMETER webLogicAppId
    The resource ID of the Web Event Manager Logic App.

.PARAMETER webLogicAppUrl
    The callback URL for the Web Event Manager Logic App.

.PARAMETER secLogicAppId
    The resource ID of the Security Event Manager Logic App.

.PARAMETER secLogicAppUrl
    The callback URL for the Security Event Manager Logic App.

.EXAMPLE
    .\ta-platform-actiongroups.ps1 -resourceGroup 'rg-platform-prod' -s2LogicAppId '/subscriptions/.../workflows/la-sev2' -s2LogicAppUrl 'https://...' -s3LogicAppId '/subscriptions/.../workflows/la-sev3' -s3LogicAppUrl 'https://...' -s4LogicAppId '/subscriptions/.../workflows/la-sev4' -s4LogicAppUrl 'https://...' -infoLogicAppId '/subscriptions/.../workflows/la-info' -infoLogicAppUrl 'https://...' -azureLogicAppId '/subscriptions/.../workflows/la-azure' -azureLogicAppUrl 'https://...' -webLogicAppId '/subscriptions/.../workflows/la-web' -webLogicAppUrl 'https://...' -secLogicAppId '/subscriptions/.../workflows/la-security' -secLogicAppUrl 'https://...'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - All Event Manager Logic Apps must be deployed first
    - Service Desk solution must be deployed in Log Analytics workspace
    - ITSM Connection should be created (for Service Desk integration)
    - User must have Contributor role on the resource group
    - ARM template files must exist in ./Platform/Infrastructure/:
      * actiongroup.exception.s2.json
      * actiongroup.exception.s3.json
      * actiongroup.warning.s4.json
      * actiongroup.info.s4.json
      * actiongroup.servicehealth.json
      * actiongroup.critical.s1.json
      * actiongroup.exception.s2web.json
      * actiongroup.critical.s2.json
      * actiongroup.security.s2.json
    
    Post-Deployment:
    - Configure alert rules to use these action groups
    - Test each action group with sample alerts
    - Verify Logic App triggers are working
    - Configure additional notification channels if needed (email, SMS, etc.)
    
    Related Scripts:
    - ta-platform-eventmanager.ps1: Deploys the Event Manager Logic Apps
    - ta-platform-incidentmanager.ps1: Deploys the Incident Manager Logic Apps
    
    Impact: Enables alert routing and automated incident creation for the entire platform.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for action groups")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Sev2 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s2LogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Sev2 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s2LogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Sev3 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s3LogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Sev3 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s3LogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Sev4 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s4LogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Sev4 Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$s4LogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Info Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$infoLogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Info Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$infoLogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Azure Service Health Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$azureLogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Azure Service Health Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$azureLogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Web Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$webLogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Web Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$webLogicAppUrl,

    [Parameter(Mandatory=$true, HelpMessage="Resource ID of the Security Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$secLogicAppId,

    [Parameter(Mandatory=$true, HelpMessage="Callback URL for the Security Event Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$secLogicAppUrl
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Action Groups"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output ""

Try {
    # Deploy Sev2 Exception Action Group
    # Routes critical exceptions to the Sev2 Event Manager
    Write-Output "Deploying Sev2 Exception action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-exceptions-s2" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $s2LogicAppId `
        -logicAppUrl $s2LogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s2.json `
        -ErrorAction Stop
    Write-Output "✓ Sev2 Exception action group deployed"
    
    # Deploy Sev3 Exception Action Group
    # Routes important exceptions to the Sev3 Event Manager
    Write-Output "Deploying Sev3 Exception action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-exceptions-s3" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $s3LogicAppId `
        -logicAppUrl $s3LogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s3.json `
        -ErrorAction Stop
    Write-Output "✓ Sev3 Exception action group deployed"
    
    # Deploy Sev4 Warning Action Group
    # Routes warning-level alerts to the Sev4 Event Manager
    Write-Output "Deploying Sev4 Warning action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-warning-s4" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $s4LogicAppId `
        -logicAppUrl $s4LogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.warning.s4.json `
        -ErrorAction Stop
    Write-Output "✓ Sev4 Warning action group deployed"
    
    # Deploy Sev4 Information Action Group
    # Routes informational events to the Info Event Manager
    Write-Output "Deploying Sev4 Information action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-information-s4" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $infoLogicAppId `
        -logicAppUrl $infoLogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.info.s4.json `
        -ErrorAction Stop
    Write-Output "✓ Sev4 Information action group deployed"
    
    # Deploy Service Health Action Group
    # Routes Azure service health events to the Azure Event Manager
    Write-Output "Deploying Service Health action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-servicehealth" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $azureLogicAppId `
        -logicAppUrl $azureLogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.servicehealth.json `
        -ErrorAction Stop
    Write-Output "✓ Service Health action group deployed"
    
    # Deploy Sev1 Critical Action Group
    # Routes highest priority critical alerts (no Logic App integration)
    Write-Output "Deploying Sev1 Critical action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-critical-s1" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./Platform/Infrastructure/actiongroup.critical.s1.json `
        -ErrorAction Stop
    Write-Output "✓ Sev1 Critical action group deployed"
    
    # Deploy Web Sev2 Action Group
    # Routes web application alerts to the Web Event Manager
    Write-Output "Deploying Web Sev2 action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-web-s2" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $webLogicAppId `
        -logicAppUrl $webLogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s2web.json `
        -ErrorAction Stop
    Write-Output "✓ Web Sev2 action group deployed"
    
    # Deploy Critical Sev2 Action Group
    # Routes critical infrastructure alerts to the Sev2 Event Manager
    Write-Output "Deploying Critical Sev2 action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-critical-s2" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $s2LogicAppId `
        -logicAppUrl $s2LogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.critical.s2.json `
        -ErrorAction Stop
    Write-Output "✓ Critical Sev2 action group deployed"
    
    # Deploy High Security Action Group
    # Routes security alerts to the Security Event Manager
    Write-Output "Deploying High Security action group..."
    New-AzResourceGroupDeployment `
        -Name "deploy-action-group-highsecurity-s2" `
        -ResourceGroupName $resourceGroup `
        -logicAppId $secLogicAppId `
        -logicAppUrl $secLogicAppUrl `
        -TemplateFile ./Platform/Infrastructure/actiongroup.security.s2.json `
        -ErrorAction Stop
    Write-Output "✓ High Security action group deployed"
    
    Write-Output ""
    Write-Output "✓ All action groups deployed successfully"
}
Catch {
    Write-Error "Failed to deploy action groups: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
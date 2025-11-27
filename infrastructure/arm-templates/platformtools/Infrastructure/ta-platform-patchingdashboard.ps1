<#
.SYNOPSIS
    Deploys the Azure Update Management patching dashboard.

.DESCRIPTION
    This script deploys an Azure Dashboard that provides visibility into the
    Update Management patching status across the platform. The dashboard displays:
    
    - Patch compliance status for all managed VMs
    - Missing updates by severity and classification
    - Update deployment schedules and history
    - Failed update installations
    - VM patching trends over time
    
    The dashboard integrates with:
    - Log Analytics workspace for update data
    - Azure Update Management for patching status
    - Azure Monitor for metrics and alerts
    
    This provides a centralized view for managing and monitoring the patching
    posture of the entire platform.

.PARAMETER workspaceResourceGroup
    The resource group containing the Log Analytics workspace.
    Example: 'rg-platform-prod'

.PARAMETER workspaceName
    The name of the Log Analytics workspace that collects update data.
    Example: 'laws-platform-prod'

.PARAMETER subscriptionId
    The Azure subscription ID where resources are deployed.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER resourceGroup
    The resource group where the dashboard will be deployed.
    Example: 'rg-platform-prod'

.PARAMETER dashboardName
    The name for the patching dashboard.
    Example: 'dash-patching-prod'

.EXAMPLE
    .\ta-platform-patchingdashboard.ps1 -workspaceResourceGroup 'rg-platform-prod' -workspaceName 'laws-platform-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-platform-prod' -dashboardName 'dash-patching-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Log Analytics workspace must exist and be collecting update data
    - Azure Update Management must be configured
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/platform/patching.defaultdashboard.json
    
    Dashboard Features:
    - Real-time patch compliance status
    - Update classification breakdown
    - Historical patching trends
    - Failed update tracking
    - Customizable time ranges
    
    Post-Deployment:
    - Pin the dashboard to your Azure Portal
    - Customize tiles as needed for your environment
    - Share with operations team members
    
    Impact: Provides centralized visibility into platform patching status and compliance.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group containing the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Name of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceName,

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for the dashboard")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Name for the patching dashboard")]
    [ValidateNotNullOrEmpty()]
    [string]$dashboardName
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Patching Dashboard"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Dashboard Name: $dashboardName"
Write-Output "Workspace: $workspaceName"
Write-Output "Workspace RG: $workspaceResourceGroup"
Write-Output ""

Try {
    # Deploy the patching dashboard
    # This dashboard provides visibility into Update Management patching status
    New-AzResourceGroupDeployment `
        -Name "deploy-patching-dashboard" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/platform/patching.defaultdashboard.json `
        -workspaceResourceGroup $workspaceResourceGroup `
        -workspaceName $workspaceName `
        -subscriptionId $subscriptionId `
        -dashboardName $dashboardName `
        -ErrorAction Stop
    
    Write-Output "✓ Patching dashboard deployed successfully"
}
Catch {
    Write-Error "Failed to deploy patching dashboard: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="

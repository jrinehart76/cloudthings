<#
.SYNOPSIS
    Deploys a Tech Stack 2 operational dashboard for application monitoring.

.DESCRIPTION
    This script deploys an Azure Dashboard that provides operational visibility for
    applications using Tech Stack 2 architecture. The dashboard displays:
    
    - Application performance metrics and trends
    - Resource health and availability
    - Error rates and exception tracking
    - Infrastructure metrics (CPU, memory, disk)
    - Application-specific KPIs
    - Resource group filtering for multi-app environments
    
    The dashboard integrates with:
    - Log Analytics workspace for log data
    - Azure Monitor for metrics
    - Application Insights for application telemetry
    
    Tech Stack 2 dashboards are designed for specific application architectures
    and provide tailored views for operations teams.

.PARAMETER workspaceResourceGroup
    The resource group containing the Log Analytics workspace.
    Example: 'rg-platform-prod'

.PARAMETER workspaceName
    The name of the Log Analytics workspace that collects application data.
    Example: 'laws-platform-prod'

.PARAMETER subscriptionId
    The Azure subscription ID where resources are deployed.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER resourceGroup
    The resource group where the dashboard will be deployed.
    Example: 'rg-platform-prod'

.PARAMETER dashboardName
    The name for the Tech Stack 2 dashboard.
    Example: 'dash-techstack2-app1-prod'

.PARAMETER applicationName
    The name of the application being monitored.
    Used for filtering and labeling dashboard components.
    Example: 'MyApplication'

.PARAMETER appGroups
    An array of resource group names containing the application resources.
    The dashboard will filter data to these resource groups.
    Example: @('rg-app1-prod', 'rg-app1-data-prod')

.EXAMPLE
    .\ta-platform-tech2dashboard.ps1 -workspaceResourceGroup 'rg-platform-prod' -workspaceName 'laws-platform-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-platform-prod' -dashboardName 'dash-techstack2-app1-prod' -applicationName 'MyApplication' -appGroups @('rg-app1-prod', 'rg-app1-data-prod')

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Log Analytics workspace must exist and be collecting application data
    - Application resources must be deployed and sending telemetry
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/platform/operations.techstack2.json
    
    Dashboard Features:
    - Application-specific performance metrics
    - Resource group filtering
    - Customizable time ranges
    - Drill-down capabilities to detailed logs
    
    Post-Deployment:
    - Pin the dashboard to your Azure Portal
    - Customize tiles for your specific application needs
    - Share with application operations team
    
    Impact: Provides centralized operational visibility for Tech Stack 2 applications.

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

    [Parameter(Mandatory=$true, HelpMessage="Name for the Tech Stack 2 dashboard")]
    [ValidateNotNullOrEmpty()]
    [string]$dashboardName,
    
    [Parameter(Mandatory=$true, HelpMessage="Name of the application being monitored")]
    [ValidateNotNullOrEmpty()]
    [string]$applicationName,

    [Parameter(Mandatory=$true, HelpMessage="Array of resource group names containing application resources")]
    [ValidateNotNullOrEmpty()]
    [array]$appGroups
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Tech Stack 2 Dashboard"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Dashboard Name: $dashboardName"
Write-Output "Application: $applicationName"
Write-Output "Workspace: $workspaceName"
Write-Output "App Resource Groups: $($appGroups -join ', ')"
Write-Output ""

Try {
    # Deploy the Tech Stack 2 operational dashboard
    # This dashboard provides application-specific monitoring views
    New-AzResourceGroupDeployment `
        -Name "deploy-techstack2-dashboard" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/platform/operations.techstack2.json `
        -workspaceResourceGroup $workspaceResourceGroup `
        -workspaceName $workspaceName `
        -subscriptionId $subscriptionId `
        -applicationName $applicationName `
        -dashboardName $dashboardName `
        -appGroups $appGroups `
        -ErrorAction Stop
    
    Write-Output "✓ Tech Stack 2 dashboard deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Tech Stack 2 dashboard: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="

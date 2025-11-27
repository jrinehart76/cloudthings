<#
.SYNOPSIS
    Deploys a Tech Stack 6 operational dashboard for application monitoring.

.DESCRIPTION
    This script deploys an Azure Dashboard that provides operational visibility for
    applications using Tech Stack 6 architecture. The dashboard displays:
    
    - Application performance metrics and trends
    - Resource health and availability
    - Error rates and exception tracking
    - Infrastructure metrics (CPU, memory, disk)
    - Application-specific KPIs
    - Container and orchestration metrics (if applicable)
    
    The dashboard integrates with:
    - Log Analytics workspace for log data
    - Azure Monitor for metrics
    - Application Insights for application telemetry
    - Container monitoring for containerized workloads
    
    Tech Stack 6 dashboards are designed for modern application architectures
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
    The name for the Tech Stack 6 dashboard.
    Example: 'dash-techstack6-app1-prod'

.PARAMETER applicationName
    The name of the application being monitored.
    Used for filtering and labeling dashboard components.
    Example: 'MyModernApp'

.EXAMPLE
    .\ta-platform-tech6dashboard.ps1 -workspaceResourceGroup 'rg-platform-prod' -workspaceName 'laws-platform-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-platform-prod' -dashboardName 'dash-techstack6-app1-prod' -applicationName 'MyModernApp'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Log Analytics workspace must exist and be collecting application data
    - Application resources must be deployed and sending telemetry
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/platform/operations.techstack6.json
    
    Dashboard Features:
    - Application-specific performance metrics
    - Modern architecture monitoring (containers, microservices)
    - Customizable time ranges
    - Drill-down capabilities to detailed logs
    
    Post-Deployment:
    - Pin the dashboard to your Azure Portal
    - Customize tiles for your specific application needs
    - Share with application operations team
    
    Impact: Provides centralized operational visibility for Tech Stack 6 applications.

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

    [Parameter(Mandatory=$true, HelpMessage="Name for the Tech Stack 6 dashboard")]
    [ValidateNotNullOrEmpty()]
    [string]$dashboardName,
    
    [Parameter(Mandatory=$true, HelpMessage="Name of the application being monitored")]
    [ValidateNotNullOrEmpty()]
    [string]$applicationName
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Tech Stack 6 Dashboard"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Dashboard Name: $dashboardName"
Write-Output "Application: $applicationName"
Write-Output "Workspace: $workspaceName"
Write-Output ""

Try {
    # Deploy the Tech Stack 6 operational dashboard
    # This dashboard provides modern application architecture monitoring views
    New-AzResourceGroupDeployment `
        -Name "deploy-techstack6-dashboard" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/platform/operations.techstack6.json `
        -workspaceResourceGroup $workspaceResourceGroup `
        -workspaceName $workspaceName `
        -subscriptionId $subscriptionId `
        -applicationName $applicationName `
        -dashboardName $dashboardName `
        -ErrorAction Stop
    
    Write-Output "✓ Tech Stack 6 dashboard deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Tech Stack 6 dashboard: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="

<#
    .DESCRIPTION
        Deploys the default Automation Account resource

    .PREREQUISITES
        None

    .TODO
        Create 'run-as' account on deployment

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$workspaceName,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$dashboardName,
    
    [Parameter(Mandatory=$true)]
    [string]$applicationName,

    [Parameter(Mandatory=$true)]
    [array]$appGroups

 )

##Deploy patching dashboards
New-AzResourceGroupDeployment `
    -Name "deploy-techstack2-dashboard" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/platform/operations.techstack2.json `
    -workspaceResourceGroup $workspaceResourceGroup `
    -workspaceName $workspaceName `
    -subscriptionId $subscriptionId `
    -applicationName $applicationName `
    -dashboardName $dashboardName `
    -appGroups $appGroups

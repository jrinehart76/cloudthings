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
    [string]$dashboardName

 )


##Deploy patching dashboards
New-AzResourceGroupDeployment `
    -Name "deploy-patching-dashboard" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/platform/patching.defaultdashboard.json `
    -workspaceResourceGroup $workspaceResourceGroup `
    -workspaceName $workspaceName `
    -subscriptionId $subscriptionId `
    -dashboardName $dashboardName

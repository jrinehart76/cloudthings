<#
    .DESCRIPTION
        Deploys Application Gateway Backend Health alert

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$customerId,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation

 )

##Create resource id variables
$actionGroupS1   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-crit-s1"

##Deploy AppGW Critical Backend Health Alert
New-AzResourceGroupDeployment `
    -Name "deploy-failed-logicapp-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.eventmanager.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS1 `
    -customerId $customerId

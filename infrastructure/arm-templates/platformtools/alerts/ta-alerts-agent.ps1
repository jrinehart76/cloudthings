<#
    .DESCRIPTION
        Deploys all standard alerts

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups

    .TODO
        Modify to only install alerts that are needed

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
    [string]$workspaceLocation,
    
    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId

 )

##Create resource id variables
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"              #critical action group resource ID
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-agent-heartbeat-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-agent-heartbeat-warning-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.warning.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

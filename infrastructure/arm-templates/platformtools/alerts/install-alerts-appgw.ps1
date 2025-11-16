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
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"          #critical action group resource ID

##Deploy AppGW Critical Backend Health Alert
New-AzResourceGroupDeployment `
    -Name "deploy-appgw-v1-unhealthly-health-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.appgwunhealthycount.v1.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-appgw-v2-unhealthly-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.appgwunhealthycount.v2.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

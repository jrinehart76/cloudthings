<#
    .DESCRIPTION
        Deploys alerts for the snapshot automation runbook

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups
        Automation Account
        Deployed runbook

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$workspaceName,

    [Parameter(Mandatory=$true)]
    [string]$fileshareName,
    
    [Parameter(Mandatory=$true)]
    [string]$customerId

 )

##Create resource id variables           
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s3"                

##Deploy all alerts
##Critical Alerts begin here
New-AzResourceGroupDeployment `
    -Name "deploy-automation-critical-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.failedsnapshot.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -fileshareName $fileshareName
<#
    .DESCRIPTION
        Deploys Microsoft SQL Alerts

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups
        Diagnostics configured on each database
    
    .EXAMPLE
        ./install-sqlAllAlerts.ps1

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (

    [Parameter(Mandatory=$true)]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$customerId,

    [Parameter(Mandatory=$true)]
    [string]$version

 )

##Create resource id variables
#$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"              
#$actionGroupCMIMS1   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-critmim-s1"              
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"             
#$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4" 

##Deploy sql alerting
    New-AzResourceGroupDeployment `
        -Name "deploy-appsvc-critical-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.appsvcplan.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -version $version `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId
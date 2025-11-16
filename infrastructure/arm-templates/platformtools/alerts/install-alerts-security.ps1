<#
    .DESCRIPTION
        Deploys all windows alerts

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
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$customerId

 )

##Create resource id variables      
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-info-s4"   

New-AzResourceGroupDeployment `
    -Name "deploy-security-info-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.warning.security.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId
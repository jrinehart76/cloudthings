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
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-highsec-s2"   

New-AzResourceGroupDeployment `
    -Name "deploy-high-security-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.security.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS2 `
    -customerId $customerId
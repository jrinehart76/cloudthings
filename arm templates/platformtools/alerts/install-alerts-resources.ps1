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
    [string]$subscriptionId
 )

##Create resource id variables
$actionGroupSvcId   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-servicehealth"              #critical action group resource ID

New-AzResourceGroupDeployment `
    -Name "deploy-resourcehealth-critical-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.resourcehealth.json `
    -alertNameResource "10m-azure-resource-alert" `
    -actionGroupId $actionGroupSvcId

New-AzResourceGroupDeployment `
    -Name "deploy-servicehealth-critical-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.servicehealth.json `
    -alertNameService "10m-azure-service-alert" `
    -actionGroupId $actionGroupSvcId
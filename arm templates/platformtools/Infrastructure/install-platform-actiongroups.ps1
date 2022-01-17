<#
    .DESCRIPTION
        Deploys both warning and critical actiongroups

    .PREREQUISITES
        Service Desk solution deployed
        ITSM Connection created       

    .TODO
        Change variables to parameters

    .NOTES
        To create the ITSM connection, run 'Set-ITSMConnection.ps1' script. The Service Desk solution is deployed as part of the Log Workspace installation.

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$s2LogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$s2LogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$s3LogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$s3LogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$s4LogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$s4LogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$infoLogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$infoLogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$azureLogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$azureLogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$webLogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$webLogicAppUrl,

    [Parameter(Mandatory=$true)]
    [string]$secLogicAppId,

    [Parameter(Mandatory=$true)]
    [string]$secLogicAppUrl
 )


##Deploy action groups for alerts
New-AzResourceGroupDeployment `
    -Name "deploy-action-group-exceptions-s2" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $s2LogicAppId `
    -logicAppUrl $s2LogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s2.json
    
New-AzResourceGroupDeployment `
    -Name "deploy-action-group-exceptions-s3" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $s3LogicAppId `
    -logicAppUrl $s3LogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s3.json
   
New-AzResourceGroupDeployment `
    -Name "deploy-action-group-warning-s4" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $s4LogicAppId `
    -logicAppUrl $s4LogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.warning.s4.json
    
New-AzResourceGroupDeployment `
    -Name "deploy-action-group-information-s4" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $infoLogicAppId `
    -logicAppUrl $infoLogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.info.s4.json
   
New-AzResourceGroupDeployment `
    -Name "deploy-action-group-servicehealth" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $azureLogicAppId `
    -logicAppUrl $azureLogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.servicehealth.json

New-AzResourceGroupDeployment `
    -Name "deploy-action-group-critical-s1" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/Infrastructure/actiongroup.critical.s1.json

New-AzResourceGroupDeployment `
    -Name "deploy-action-group-web-s2" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $webLogicAppId `
    -logicAppUrl $webLogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.exception.s2web.json

New-AzResourceGroupDeployment `
    -Name "deploy-action-group-critical-s2" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $s2LogicAppId `
    -logicAppUrl $s2LogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.critical.s2.json

New-AzResourceGroupDeployment `
    -Name "deploy-action-group-highsecurity-s2" `
    -ResourceGroupName $resourceGroup `
    -logicAppId $secLogicAppId `
    -logicAppUrl $secLogicAppUrl `
    -TemplateFile ./Platform/Infrastructure/actiongroup.security.s2.json
   
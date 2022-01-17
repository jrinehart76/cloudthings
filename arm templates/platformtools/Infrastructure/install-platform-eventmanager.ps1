<#
    .DESCRIPTION
        Deployes Event Manager Logic Apps

    .PREREQUISITES
        None

    .DEPENDENCIES
        Az.Resources

    .PARAMETER logicAppEnv
        The environment for deployment: i.e. Dev or Prod
    .PARAMETER logicAppLocation 
        Azure region for deployment
    .PARAMETER dynamicsCrmOnlineConnectionName 
        Name of the dynamics crm web api connection.  If this does not exist, a new one will be created
    .PARAMETER resourceGroup 
        Name of the resource group for deployment
    .PARAMETER accountGUID 
        GUID of the customer account from dynamics crm
    .PARAMETER monitoringGUID 
        GUID of the monitoring account from dynamics crm
    .PARAMETER integrationAccountName 
        Name of the integration account to use.  If it does not exist, a new one will be created
    .PARAMETER deploymentVersion 
        Version of the deployment: two digit month and two digit year, i.e. 0320

    .TODO
        None

    .NOTES
        AUTHOR: jrinehart, dnite
        LASTEDIT: 2020.3.6

    .CHANGELOG

    .VERSION
        2.0.0
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$logicAppEnv,

    [Parameter(Mandatory=$true)]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true)]
    [string]$dynamicsCrmOnlineConnectionName,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$accountGUID,
    
    [Parameter(Mandatory=$true)]
    [string]$monitoringGUID,

    [Parameter(Mandatory=$true)]
    [string]$integrationAccountName,

    [Parameter(Mandatory=$true)]
    [string]$deploymentVersion
 )

New-AzResourceGroupDeployment `
    -Name "deploy-10m-sev2-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-sev2events.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-sev3-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-sev3events.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-sev4-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-sev4events.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-info-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-infoevents.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-security-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-securityevents.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-azure-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-azureevents.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-web-event-managers-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./AlertManager/alertmanager-webevents.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -relatedAccountGUID $accountGUID `
    -monitoringContactGUID $monitoringGUID `
    -integrationAccountName $integrationAccountName `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName
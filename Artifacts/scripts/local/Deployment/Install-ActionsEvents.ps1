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

#Deploy Logic Apps
$error.clear()
try {
    & "./Platform/Infrastructure/install-platform-eventmanager.ps1" -logicAppEnv $logicAppEnv `
                                                                    -logicAppLocation $logicAppLocation `
                                                                    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName `
                                                                    -resourceGroup $resourceGroup `
                                                                    -accountGUID $accountGUID `
                                                                    -monitoringGUID $monitoringGUID `
                                                                    -integrationAccountName $integrationAccountName `
                                                                    -deploymentVersion $deploymentVersion
} catch {
    Write-Output "Failed to deploy event manager logic apps [$($error)]"
    Break
}
if (!$error) {
    Write-Output "Successfully deployed event manager logic apps"
}

# Get Logic App callback Urls
$sev2la = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-sev-2"
$sev2cb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-sev-2" -TriggerName "manual"
$sev3la = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-sev-3"
$sev3cb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-sev-3" -TriggerName "manual"
$sev4la = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-sev-4"
$sev4cb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-sev-4" -TriggerName "manual"
$infola = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-info"
$infocb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-info" -TriggerName "manual"
$azurela = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-azure"
$azurecb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-azure" -TriggerName "manual"
$secla = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-security"
$seccb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-security" -TriggerName "manual"
$webla = Get-AzLogicApp -ResourceGroupName $resourceGroup -Name "10m-event-web"
$webcb = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroup -Name "10m-event-web" -TriggerName "manual"

# Deploy Action Groups
$error.clear()
try {
    & "./Platform/Infrastructure/install-platform-actiongroups.ps1" -resourceGroup $resourceGroup `
                                                                    -s2LogicAppId $sev2la.Id `
                                                                    -s2LogicAppUrl $sev2cb.Value `
                                                                    -s3LogicAppId $sev3la.Id `
                                                                    -s3LogicAppUrl $sev3cb.Value `
                                                                    -s4LogicAppId $sev4la.Id `
                                                                    -s4LogicAppUrl $sev4cb.Value `
                                                                    -infoLogicAppId $infola.Id `
                                                                    -infoLogicAppUrl $infocb.Value `
                                                                    -azureLogicAppId $azurela.Id `
                                                                    -azureLogicAppUrl $azurecb.Value `
                                                                    -webLogicAppId $webla.Id `
                                                                    -webLogicAppUrl $webcb.Value `
                                                                    -secLogicAppId $secla.Id `
                                                                    -secLogicAppUrl $seccb.Value 
} catch {
    Write-Output "Failed to deploy azure monitor action groups [$($error)]"
    Break
}
if (!$error) {
    Write-Output "Successfully deployed azure monitor action groups"
}
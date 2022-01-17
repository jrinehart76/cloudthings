<#
    .DESCRIPTION
        Removes alerts from a customer environment prior to upgrade

    .PREREQUISITES
        Alerts
        Powershell

    .DEPENDENCIES
        Az.Resources

    .PARAMETER ResourceGroupName 
        The resource group containing the alerts

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.5.6

    .CHANGELOG

    .VERSION
        1.0.0
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

$alerts = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType microsoft.insights/scheduledqueryrules | Where-Object {($_.Name -like "10m-*") -and ($_.Name -notlike "*oracle*")}
$actions = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType microsoft.insights/actiongroups | Where-Object Name -like "10m-*"
$logicApps = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Logic/workflows | Where-Object Name -like "10m-*"

if ($alerts) {
    foreach ($alert in $alerts) {
        Write-Output "[$($alert.Name)] - Attempting Removal"
        $error.clear()
        try {
            Remove-AzResource -ResourceId $alert.ResourceId -Force | Out-Null
        }
        catch {
            Write-Error "[$($alert.Name)] - Removal Failed [$($error)]"
        }
        if (!$error) {
            Write-Output "[$($alert.Name)] - Successfully Removed"
        }
    }
}
else {
    Write-Output "No 10M alerts found"
}

if ($actions) {
    foreach ($action in $actions) {
        Write-Output "[$($action.Name)] - Attempting Removal"
        $error.clear()
        try {
            Remove-AzResource -ResourceId $action.ResourceId -Force | Out-Null
        }
        catch {
            Write-Error "[$($action.Name)] - Removal Failed [$($error)]"
        }
        if (!$error) {
            Write-Output "[$($action.Name)] - Successfully Removed"
        }
    }
}
else {
    Write-Output "No 10M Action Groups found"
}

if ($logicApps) {
    foreach ($logicApp in $logicApps) {
        Write-Output "[$($logicApp.Name)] - Attempting Removal"
        $error.clear()
        try {
            Remove-AzResource -ResourceId $logicApp.ResourceId -Force | Out-Null
        }
        catch {
            Write-Error "[$($logicApp.Name)] - Removal Failed [$($error)]"
        }
        if (!$error) {
            Write-Output "[$($logicApp.Name)] - Successfully Removed"
        }
    }
}
else {
    Write-Output "No 10M Logic Apps found"
}
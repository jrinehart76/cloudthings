<#
    .DESCRIPTION
        Enables or Reconfigures resources which support Diagnostics Setttings.
        Runs from an Azure Automation account.

    .PARAMETER
        location 
            The Azure location to search and configure (eastus; southcentralus)
    
    .PARAMETER
        workspaceId
            The workspace where diagnostics are stored.

    .PREREQUISITES
        Existing AzureRunAsAccount in Automations account

    .DEPENDENCIES
        Az.Accounts
        Az.Resources
        Az.ResourceGraph
        Az.Monitor

    .TODO

    .NOTES
        AUTHOR: cwitcher, jrinehart
        LASTEDIT: 2020.1.21
        
    .CHANGELOG

    .VERSION
        1.0.0
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$location,

    [Parameter(Mandatory = $true)]
    [string]$workspaceId

#    [Parameter(Mandatory = $true)]
#    [string]$subscription
)

$requiredDiagnosticName = "10mDiagnosticsLog"
<#
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal

        $subscriptions = (Get-AzContext).Account.ExtendedProperties.Subscriptions
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
$subscriptions
#>
$odataFilter = "Location eq '" + $location + "'"
#$searchQuery = 'Resources | where location=="' + $location + '" | where type !contains "microsoft.compute" and type !contains "microsoft.operationsmanagement" and type !contains "microsoft.insights" and type !contains "workspaces" and type !contains "routetables" | where id contains "' + $subscription + '" | project name, id'
#$resources = Search-AzGraph -Query $searchQuery -First 5000 -Verbose
$resources = Get-AzResource -ODataQuery $odataFilter

ForEach ($resource in $resources) {
    Try {
        $DiagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.resourceId -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
        if (!($DiagnosticSettings)) {
                         
            Set-AzDiagnosticSetting -Name $requiredDiagnosticName `
                -workspaceId $workspaceId `
                -ResourceId $resource.resourceId `
                -Enabled $True `
                -ErrorAction 'Stop' -WarningAction 'SilentlyContinue'
        
            Write-Output "Enabling metrics and logs with default categories on [$($resource.name)]."
        }
        elseif ($DiagnosticSettings -and ($DiagnosticSettings.Name -ne $requiredDiagnosticName)) {
                       
            Remove-AzDiagnosticSetting -ResourceId $resource.resourceId `
                -WarningAction 'SilentlyContinue' `
                -ErrorAction 'SilentlyContinue'
                        
            Set-AzDiagnosticSetting -Name $requiredDiagnosticName `
                -workspaceId $workspaceId `
                -ResourceId $Resource.resourceId `
                -Enabled $True `
                -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
            Write-Output "Updated metrics and logs with default categories on [$($resource.Name)]."                    
        }
        else {
            Write-Output "Diagnostic [$($DiagnosticSettings.name)] already exist on [$($Resource.name)]."
        }            
    }
    Catch {
        Write-Output "Cannot enable diagnostic settings on [$($resource.Name)]"
    }
    if ($DiagnosticSettings) {
        Clear-Variable -Name 'DiagnosticSettings'
    }
    Clear-Variable -Name 'DiagnosticSettings'
    [GC]::Collect()
}
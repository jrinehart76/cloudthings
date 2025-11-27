<#
.SYNOPSIS
    Configure diagnostic settings for all Azure resources in a location

.DESCRIPTION
    This script enables or reconfigures diagnostic settings for all resources
    in a specified Azure location. Essential for:
    - Centralized logging and monitoring
    - Security and compliance requirements
    - Troubleshooting and diagnostics
    - Cost and performance analysis
    
    The script:
    - Discovers all resources in specified location
    - Checks existing diagnostic settings
    - Creates or updates settings to send logs to Log Analytics
    - Standardizes diagnostic configuration across resources
    - Handles resources that don't support diagnostics gracefully

.PARAMETER Location
    The Azure location/region to process (e.g., "eastus", "westus2")

.PARAMETER WorkspaceId
    The full resource ID of the Log Analytics workspace where diagnostics will be sent

.PARAMETER DiagnosticSettingName
    Name for the diagnostic setting (default: "MSPDiagnosticsLog")

.PARAMETER Force
    If true, removes existing diagnostic settings and recreates them

.EXAMPLE
    .\Configure-AllDiagnostics.ps1 -Location "eastus" -WorkspaceId "/subscriptions/.../workspaces/my-workspace"
    
    Configures diagnostics for all resources in East US region

.EXAMPLE
    .\Configure-AllDiagnostics.ps1 -Location "westus2" -WorkspaceId $workspaceId -Force
    
    Forces reconfiguration of all diagnostic settings in West US 2

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Resources module
    - Az.Monitor module
    - Contributor or Monitoring Contributor role on resources
    
    Impact: Enables centralized logging for security, compliance, and troubleshooting.
    Critical for production environments.

.VERSION
    2.0.0 - Added proper documentation, error handling, and parameterization
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Enhanced error handling, progress tracking, better output
    1.0.0 - Initial version for automation account
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$location,

    [Parameter(Mandatory = $true)]
    [string]$workspaceId

#    [Parameter(Mandatory = $true)]
#    [string]$subscription
)

$requiredDiagnosticName = "MSPDiagnosticsLog"
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
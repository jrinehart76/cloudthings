<#
    .DESCRIPTION
        This script will get all allResources in a subscription and if the resource type matches the resource hash table, diagnostics settings will
        be read. For each object scanned, the details about the diagnostics are gathered and output to a CSV file. The CSV file will need to be
        imported into an Excel worksheet to have readable formatting.
       
    .PREREQUISITES
        Must be run from Windows system
        Cannot be run elevated as Administrator
      
    .EXAMPLE
        ./Get-PaaSExtensionStatus.ps1

    .TO-DO
        Add ability to audit all subscriptions if desired
      
    .NOTES
        AUTHOR(s):Erlin Tego

    .VERSION

    .CHANGELOG
        12172019 - Updated Path, Modified terminal output, Remove parameters - Rhino  
#>
Param()

$allSubs = Get-AzSubscription
$monitored = @()

$resList = @('Microsoft.ContainerService/managedClusters', 'Microsoft.Logic/workflows', 'Microsoft.DBforMySQL/servers', 'Microsoft.Sql/servers', 'Microsoft.Sql/servers/databases', 'Microsoft.Network/applicationGateways', 'Microsoft.RecoveryServices/vaults')

foreach ($sub in $allSubs) {
    Set-AzContext -Subscription $sub.Name
    $allResources = Get-AzResource
    Write-Output "Getting resources in [$($sub.Name)]"
    Write-Output ""
    foreach ($res in $allResources) {
        foreach ($paas in $resList) {
            if ($res.ResourceType -eq $paas) {
                $monitored += $res
            }
        }
    }
    foreach ($service in $monitored) {
        $diags = Get-AzDiagnosticSetting -ResourceId $service.ResourceId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if (!($diags.WorkspaceId)) {
            $output = $_.allResources | ForEach-Object { 
                [PSCustomObject]@{ 
                    "Resource Name"    = $service.Name
                    "Resource Type"    = $service.Type
                    "Diagnostics Name" = "Missing"
                    "Metrics Enabled"  = "Missing"
                    "Logs Enabled"     = "Missing"
                    "WorkspaceId"      = "Missing" -join ','
                }
            }
            $output | Export-Csv -Path "$([environment]::GetFolderPath("mydocuments"))\PaaSExtensionAuditOnDemand.csv" -delimiter ";" -Append -force -notypeinformation
        }
        if ($diags.WorkspaceId) {
            $output = $_.allResources | ForEach-Object { 
                [PSCustomObject]@{ 
                    "Resource Name"    = $service.Name
                    "Resource Type"    = $service.Type
                    "Diagnostics Name" = $diags.Name
                    "Metrics Enabled"  = $diags.Metrics[0].Enabled
                    "Logs Enabled"     = $diags.Logs[0].Enabled
                    "WorkspaceId"      = $diags.WorkspaceId -join ','
                }
            }
            $output | Export-Csv -Path "$([environment]::GetFolderPath("mydocuments"))\PaaSExtensionAuditOnDemand.csv" -delimiter ";" -Append -force -notypeinformation
        } 
    }
    Write-Output ""
}
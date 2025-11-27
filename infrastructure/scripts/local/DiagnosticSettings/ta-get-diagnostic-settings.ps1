<#
    .DESCRIPTION


    .PREREQUISITES
       

    .Example
       

    .TODO
      

    .NOTES
        

    .VERSION
      

    .CHANGELOG  
    
    
#>

$resources = Get-AzResource
$diagList = @()

foreach ($res in $resources) {
    try {
        $settings = Get-AzDiagnosticSetting -ResourceId $res.ResourceId -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
    }
    catch {
        Continue
    }
    
    Write-Output "[$($res.Name)] is being checked."
    if ($settings) {
        $diagList += $res
    }
}

Write-Output "[]"
$diagList.Name
Write-Output "[]"

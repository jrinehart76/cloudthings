<#
    .DESCRIPTION
        

    .PREREQUISITES
       

    .Example
        Remove-DiagnosticSettings -diagName '<name>'
        Remove-DiagnosticSettings -diagName '<name>' -tagName '<tag name>' -tagValue '<tag value>'     

    .TODO
      

    .NOTES
        

    .VERSION
      

    .CHANGELOG  
    
    
#>

param (
    $tagName,
    $tagValue,
    $Throttle = 5
)

$Jobs = @()

if ($tagValue) {
    Write-Output "Getting resources matching tag and value [$($tagName)] [$($tagValue)]."
    $tagTable = @{$tagName = $tagValue}
    $resourceGroups = Get-AzResourceGroup -Tag $tagTable
    foreach ($resourceGroup in $resourceGroups) {
        $list = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
        if ($list) {
            $resources += $list
        }
    }
}

if (!($tagValue)) {
    Write-Output "Getting all resources."
    $resources = Get-AzResource
}

$RemoveAzDiagnosticSettingsJob = {
    param (
        $res
    )
    Remove-AzDiagnosticSetting -ResourceId $res.ResourceId `
        -WarningAction 'SilentlyContinue' `
        -ErrorAction 'SilentlyContinue'
}

foreach ($res in $resources) {
    try {
        $diagSettings = Get-AzDiagnosticSetting -ResourceId $res.ResourceId -ErrorAction 'Stop' -WarningAction 'SilentlyContinue'
    } catch {
        if ($_.Exception.ToString().Contains("BadRequest")) {
            Continue
        }
    }

    if ($diagSettings.Name) {

        $RunningJobs = $Jobs | Where-Object {$_.State -eq 'Running'}

        if ($RunningJobs.Count -ge $Throttle) {
            Write-Output "Max job queue of ${Throttle} reached. Please wait while existing jobs are processed..."
            $RunningJobs | Wait-Job -Any | Out-Null
        }

        $Jobs += Start-Job -ScriptBlock $RemoveAzDiagnosticSettingsJob -ArgumentList $res
        Write-Output "Diagnostics removed from resource [$($res.Name)]."

    } else {
        Write-Output "Diagnostics not found on resource [$($res.Name)]."
    }
}

if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs | Receive-Job
$Jobs | Remove-Job
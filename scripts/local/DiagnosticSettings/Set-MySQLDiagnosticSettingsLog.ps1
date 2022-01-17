<#
    .DESCRIPTION
        

    .PREREQUISITES
       

    .Example
        Set-DiagnosticSettingsLogs -WorkspaceName '<name>' -TagName '<value>' -TagValue '<value>'
        Set-DiagnosticSettingsLogs -resourceType 'Microsoft.sql' -workspaceId '<workspace resource Id>' ##if using this, make sure you use Microsoft.<resource type here> in the variable switch
        Set-DiagnosticSettingsLogs -WorkspaceName '<name>'

    .TODO
      

    .NOTES
        To find the workspace resource Id, set the context to the subscription that contains the workspace then run this to find the workspaces:
            ## $workspaceId = Get-AzResource -ResourceType 'Microsoft.OperationalInsights/workspaces'
            ## $workspaceId.ResourceId

        If you know the name of the resource, you can run the command like this
            ## $workspaceId = Get-AzResource -ResourceType 'Microsoft.OperationalInsights/workspaces' | Where-Object { $_.Name -eq '<name here>' }
            ## $workspaceId.ResourceId

    .VERSION
      

    .CHANGELOG  
    
    
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$workspaceId,

    [Parameter(Mandatory = $true)]
    [string]$region,

    [Parameter(Mandatory = $false)]
    [string]$tagName,

    [Parameter(Mandatory = $false)]
    [string]$tagValue,

    [Parameter(Mandatory = $false)]
    [string]$resourceType,

    [Parameter(Mandatory = $false)]
    [int]$throttle = 5
)

$jobs = @()

$diagnosticSettingName = "MySQLdiagnosticsLog"

$odataFilter = "Location eq '" + $region + "'"

if ($tagValue) {
    Write-Output "Getting MySQL resources matching tag and value [$($tagName)] [$($tagValue)]."
    $tagTable = @{$tagName = $tagValue}
    $resourceGroups = Get-AzResourceGroup -Tag $tagTable -Location $region
    foreach ($resourceGroup in $resourceGroups) {
        $list = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceType 'Microsoft.DBforMySQL/servers' -ODataQuery $odataFilter
        if ($list) {
            $resources += $list
        }
    }
}

if (!($tagValue)) {
    Write-Output "Getting all MySQL resources."
    $resources = Get-AzResource -ResourceType 'Microsoft.DBforMySQL/servers' -ODataQuery $odataFilter
}    

if (!($workspaceId)) {
    Write-Output "No workspace name specified, cannot continue."
    return
}

$SetAzDiagnosticSettingsJob = {
    param (
        $diagnosticSettingName, $workspaceId, $resource
    )
    Set-AzDiagnosticSetting -Name $diagnosticSettingName `
        -WorkspaceId $workspaceId `
        -ResourceId $resource.ResourceId `
        -Enabled $True `
        -ErrorAction 'Continue' `
        -WarningAction 'SilentlyContinue'
}

$version
foreach ($resource in $resources) {
    try {
        $diagSettings = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction 'Stop' -WarningAction 'SilentlyContinue'
    }
    catch {
        if ($_.Exception.ToString().Contains("BadRequest")) {
            Continue
        }
    }

    if (!($diagSettings.WorkspaceId)) {

        $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }

        if ($runningJobs.Count -ge $throttle) {
            Write-Output "Max job queue of ${Throttle} reached. Please wait while existing jobs are processed..."
            $runningJobs | Wait-Job -Any | Out-Null
        }
        
        $jobs += Start-Job -ScriptBlock $SetAzDiagnosticSettingsJob -ArgumentList $diagnosticSettingName, $workspaceId, $resource, $version
        Write-Output "Enabling Log Analytics Diagnostics with default categories on [$($resource.Name)]."
        
    }
    else {
        Write-Output "[$($diagSettings.Name)] already exist on [$($resource.Name)]."
    }
}

if ($jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $jobs | Wait-Job | Out-Null
}

$jobs | Receive-Job
$jobs | Remove-Job
<#
    .DESCRIPTION
        

    .PREREQUISITES
       

    .Example
        Set-DiagnosticSettingsHub -tagName '<name>' -tagValue '<value>' -subscriptionId '<id>' -hubName '<name of the hub>' -hubRG '<resource group of the hub>' -hubNamespace '<event hub namespace>'
        Set-DiagnosticSettingsHub -tagName 'environment' -tagValue 'prod' -subscriptionId '1234-56789-12345b' -hubName 'insights-logs-diagnostics' -hubRG 'rg-prod-mgmt' -hubNamespace 'prod-eh-eastus'
  
    .TODO
      

    .NOTES
        

    .VERSION
      

    .CHANGELOG  
    
    
#>

param (
    $tagName,
    $tagValue,
    $subscriptionId,
    $hubName,
    $hubRG,
    $hubNamespace,
    $throttle = 5
)

$jobs = @()

$diagnosticSettingName = "diagnosticsHub"
$authorizationId = "/subscriptions/$subscriptionId/resourceGroups/$hubRG/providers/Microsoft.EventHub/namespaces/$hubNamespace/authorizationrules/RootManageSharedAccessKey"

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

if (!($TagValue)) {
    Write-Output "No tag value specified, getting all resources"
    $resources = Get-AzResource
}

if (!($hubName)) {
    Write-Output "No Event Hub specified, cannot continue."
    return
}

$SetAzDiagnosticSettingsJob = {
    param (
        $diagnosticSettingName, $authorizationId, $hubName, $resource
    )
    Set-AzDiagnosticSetting -Name $diagnosticSettingName `
        -EventHubName $hubName `
        -EventHubAuthorizationRuleId $authorizationId `
        -ResourceId $resource.ResourceId `
        -Enabled $True `
        -ErrorAction 'Continue' `
        -WarningAction 'SilentlyContinue'
}

foreach ($resource in $resources) {
    try {
        $diagSetting = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction 'Stop' -WarningAction 'SilentlyContinue'
    }
    catch {
        if ($_.Exception.ToString().Contains("BadRequest")) {
            Continue
        }
    }

    if (!($diagSetting.EventHubAuthorizationRuleId)) {

        $RunningJobs = $jobs | Where-Object { $_.State -eq 'Running' }

        if ($RunningJobs.Count -ge $Throttle) {
            Write-Output "Max job queue of ${Throttle} reached. Please wait while existing jobs are processed..."
            $RunningJobs | Wait-Job -Any | Out-Null
        }

        $jobs += Start-Job -ScriptBlock $SetAzDiagnosticSettingsJob -ArgumentList $diagnosticSettingName, $authorizationId, $hubName, $resource
        Write-Output "Enabling Event Hub diagnostics with default categories on [$($resource.Name)]."
        
    }
    else {
        Write-Output "[$($diagSetting.Name)] already exist on [$($resource.Name)]."
    }
}

if ($jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $jobs | Wait-Job | Out-Null
}

$jobs | Receive-Job
$jobs | Remove-Job
$subscription = "GCCS"
$actionToFind = "Microsoft.Web/serverFarms/join/action"
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subscription -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

foreach ($role in Get-AzureRmRoleDefinition) {
    $formattedAction = $actionToFind
    if ($role.Actions | ?{$_ -eq "*"}) {
        Write-Output "$($role.Name): *"
    }
    if ($role.Actions | ?{$_ -eq $formattedAction}) {
        Write-Output "$($role.Name): $($role.Actions | ?{$_ -eq $formattedAction})"
    }
    while ($formattedAction.Split("/").Count -gt 1) {
        $formattedAction = $formattedAction.Substring(0, $formattedAction.LastIndexOf("/"))
        if ($role.Actions | ?{$_ -eq ($formattedAction + "/*")}) {
            Write-Output "$($role.Name): $($role.Actions | ?{$_ -eq ($formattedAction + "/*")})"
        }
    }
}
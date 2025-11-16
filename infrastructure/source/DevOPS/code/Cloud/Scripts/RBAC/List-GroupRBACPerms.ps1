$subscription = "subscription-nonprod-001-DATALAKE"
$groupName = "EDLGlobalDevs"
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subscription -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

$outputPath = ".\Scripts\RBAC\$($groupName).csv"
Write-Output "`nGetting Role Assignments for $($groupName)"
Get-AzureRmRoleAssignment -ObjectId (Get-AzureRmADGroup -DisplayName $groupName).Id.Guid | select DisplayName, Scope, RoleDefinitionName | Export-Csv -NoTypeInformation -Path $outputPath
Write-Output "`nRole Assignments output to $($outputPath)`n"
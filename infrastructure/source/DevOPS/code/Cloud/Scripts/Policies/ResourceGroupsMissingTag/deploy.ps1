$subName = "subscription-poc-001"
$policyName = "Policy-AM-EastUS-POC-RGsMissingTag"
$policyFile = ".\Scripts\Policies\ResourceGroupsMissingTag\policy.json"

##################################
Import-Module AzureRM
Add-AzureRMAccount
#Import-AzureRmContext -Path <PathToContextJSON>

Write-Host "Selecting subscription: $($subName)"
Select-AzureRmSubscription -SubscriptionName $subName | Out-Null

$policy = (Get-Content $policyFile | ConvertFrom-Json).properties
$displayName = $policy.displayName
$description = $policy.description
$policyRule = $policy.policyRule | ConvertTo-Json -Depth 10 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
$parameters = $policy.parameters | ConvertTo-Json -Depth 10 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
$metadata = $policy.metadata | ConvertTo-Json -Depth 10 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
$mode = $policy.mode


Write-Host "Deploying Policy"
New-AzureRmPolicyDefinition `
    -Name $policyName `
    -DisplayName $displayName `
    -Description  $description `
    -Policy $policyRule `
    -Parameter $parameters `
    -Metadata $metadata `
    -Mode $mode

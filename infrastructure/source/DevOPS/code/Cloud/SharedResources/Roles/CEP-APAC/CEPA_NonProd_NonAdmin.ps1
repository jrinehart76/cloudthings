<#
param (
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	[parameter(Mandatory=$true)]
	$Region,
	[string]
	[parameter(Mandatory=$true)]
	$Environment
)

function Assign-RoleDefinition {
	param (
	  $ResourceType,
	  $ResourceGroupName,
	  $RoleDefinitionName,
	  $PrincipalId
	)

	$resources = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	foreach($r in $resources) {
	Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	try {
		New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	-ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	write-Output "Complete."
	} catch {
		Write-Output $Error[0]
	}

	}
}
#>
<#
subscription-nonprod-002
00000000-0000-0000-0000-000000000000

U-Customer-CEPAPAC-Admins
00000000-0000-0000-0000-000000000000

U-Customer-CEPAPAC-Devs
00000000-0000-0000-0000-000000000000

#>

$subId = '00000000-0000-0000-0000-000000000000'
[array]$PrincipalId = "00000000-0000-0000-0000-000000000000"

# set subscription to CUST-A-ap-nonprod-v2
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){

# Dev 
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "rg-region2-SoutheastAsia-Dev-CEPA" `
-RoleDefinitionName "Reader"

}
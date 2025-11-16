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
CUST-A-AP-NONPROD-V2
7ab6c981-15d8-44aa-a555-0f2ca122f747

U-CUST-A-CEPAPAC-Admins
7aa941b5-dd3b-4160-837b-b7c953874067

U-CUST-A-CEPAPAC-Devs
f01c092b-c095-442d-9780-44365c726456

#>

$subId = '7ab6c981-15d8-44aa-a555-0f2ca122f747'
[array]$PrincipalId = "7aa941b5-dd3b-4160-837b-b7c953874067"

# set subscription to CUST-A-ap-nonprod-v2
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){

# Dev 
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-AP-SoutheastAsia-Dev-CEPA" `
-RoleDefinitionName "Contributor"

}
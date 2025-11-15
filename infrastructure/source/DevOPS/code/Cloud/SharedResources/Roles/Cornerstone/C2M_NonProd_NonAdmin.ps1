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
ELC-AM-NONPROD-CORNERSTONE
fea13a4d-5f74-44cc-8611-0cbc35235413

G-AM-Cornerstone-NonProd
9f69c86a-fd21-42f7-9e60-dc43b3c55a1c

G-AM-Cornerstone-NonProd-Admin
3b2c472d-f6bd-42e0-b25f-c8517168c3b5

G-AM-Cornerstone-Prod
acc34151-ba9c-4597-ac3f-63ec1fa614bf

G-AM-Cornerstone-Prod-Admin
91d978c8-e703-4d9a-b3e7-6164346fd3d2
#>

$subId = 'fea13a4d-5f74-44cc-8611-0cbc35235413'
[array]$PrincipalId = "9f69c86a-fd21-42f7-9e60-dc43b3c55a1c"

# set subscription to datalake
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){

# Dev 
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-AM-EastUS-Dev-C2M" `
-RoleDefinitionName "Reader"


# NonProd Shared  
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-AM-EastUS-NonProd-C2M" `
-RoleDefinitionName "Reader"

}
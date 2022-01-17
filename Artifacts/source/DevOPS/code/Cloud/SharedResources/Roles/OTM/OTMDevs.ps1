param (
	[string]
	[parameter(Mandatory=$true)]
	$PrincipalId,
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
	Write-Output "Resource count: $($resources.Count)"

	foreach($r in $resources) {
	Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	-ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	write-Output "Complete."
	}
}


Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "Virtual Machine Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Account Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "Redis Cache Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.Network/loadBalancers" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-ResourceType "Microsoft.ContainerRegistry/registries" -RoleDefinitionName "Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM" `
-RoleDefinitionName "Reader"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-OTM-ACS" `
-RoleDefinitionName "Reader"

param (
	[string]
	[parameter(Mandatory=$true)]
	$PrincipalId,
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	$DataLakeLocation,
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


Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Blob Data Contributor (Preview)"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Account Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.StreamAnalytics/streamingjobs" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "Redis Cache Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.Network/loadBalancers" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-CEPLATAM" `
-ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "Contributor"

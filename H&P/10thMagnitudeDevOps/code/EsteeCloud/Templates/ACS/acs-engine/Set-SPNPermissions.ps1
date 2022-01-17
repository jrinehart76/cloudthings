param (
	[string]
	[parameter(Mandatory=$true)]
	$ResourceGroup,
	[string]
	[parameter(Mandatory=$true)]
	$SPID,
	[string]
	[parameter(Mandatory=$true)]
	$MasterSubnetID,
	[string]
	[parameter(Mandatory=$true)]
	$AgentsSubnetID
)

# Set permissions on the resource group for the SP
$GUID = (Get-AzureRmADServicePrincipal -ApplicationId $SPID).Id.Guid 
$group = Get-AzureRmResourceGroup $ResourceGroup
New-AzureRmRoleAssignment -ObjectId $GUID -Scope $group.ResourceId -RoleDefinitionName "Contributor" -Verbose
New-AzureRmRoleAssignment -ObjectId $GUID -Scope $MasterSubnetID -RoleDefinitionName "Network Contributor"
New-AzureRmRoleAssignment -ObjectId $GUID -Scope $AgentsSubnetID -RoleDefinitionName "Network Contributor"


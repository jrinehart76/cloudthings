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

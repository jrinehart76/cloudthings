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

	$resources = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	foreach($r in $resources) {
	Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	try {
		New-AzRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	-ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	write-Output "Complete."
	} catch {
		Write-Output $Error[0]
	}

	}
}


$subId = '00000000-0000-0000-0000-000000000000'
$PrincipalID = @()
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_All')[0].Id
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_Fin')[0].Id
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_DTC')[0].Id
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_HR')[0].Id
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_SC')[0].Id
$PrincipalID += (Get-AzADGroup -SearchString 'U-Customer-EDLGlobalQA_CsMkt')[0].Id




# set subscription to datalake
Select-AzSubscription -Subscription $subId

foreach($p in $PrincipalId){



# ASE 

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Website Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Web Plan Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Logic App Contributor"

# Storage
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-DataStorage" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

# ADFS

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-RoleDefinitionName "Reader"



# PAAS 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-OtherPAAS" `
-RoleDefinitionName "Reader"

# PAAS 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-DataBrick" `
-RoleDefinitionName "Reader"

# PAAS 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Servers" `
-RoleDefinitionName "Reader"

# PAAS 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-RoleDefinitionName "Reader"


}


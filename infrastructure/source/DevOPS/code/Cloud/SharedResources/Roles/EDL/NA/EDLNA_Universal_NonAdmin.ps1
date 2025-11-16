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


$subId = '00000000-0000-0000-0000-000000000000'
[array]$PrincipalId = '00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000', `
'00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000', `
'00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-000000000000', `
'00000000-0000-0000-0000-000000000000'

# set subscription to datalake
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){



# ASE 

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Reader"

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Website Contributor"

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Web Plan Contributor"



# IAAS
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-RoleDefinitionName "Reader"


# Ingest
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-RoleDefinitionName "Reader"


# PAAS 
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.StreamAnalytics/streamingjobs" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.EventHub/namespaces" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"

New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-RoleDefinitionName "Reader"

}
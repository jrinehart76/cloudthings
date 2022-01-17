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


$subId = '76ad4304-5346-4b50-a862-f652c40ee4a5'
[array]$PrincipalId = 'b2de75db-f55a-4747-a060-4b05a5cb4501','fe52e7de-e502-425b-9963-b0630b7e87f7','2f4d3eb6-7b3f-4b67-80aa-13d7134dfb15', `
'fbfa3e1f-091f-4fb7-82c8-c0ab5b083a35','3b1d8f69-afd6-4c8b-886e-781ac7b3bc91','467e29d7-c48b-4b34-93e6-fbf7fa89b11c','529c353c-dfae-46ec-9fa0-5254a57ca6ac', `
'a98c922a-0fe5-46f5-a1d3-d37682bd1076','148488b4-2158-4800-a8ed-606f0af04c18','d5d06c4c-3da8-4b5f-bc78-d3a750641c0a','73f78acc-c130-40cc-8729-f40d1cff89fb', `
'6395d527-ec9e-4aca-b65f-a5b4047b645b'

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
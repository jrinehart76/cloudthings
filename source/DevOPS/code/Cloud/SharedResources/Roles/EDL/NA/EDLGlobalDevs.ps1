param (
	[string]
	[parameter(Mandatory=$true)]
	$PrincipalId,
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	[parameter(Mandatory=$true)]
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

	foreach($r in $resources) {
	Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	-ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	write-Output "Complete."
	}
}

# ASE 
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Website Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Web Plan Contributor"

# Data Lake 
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($DataLakeLocation)-$($Environment)-EDLNA-DL" `
-ResourceType "Microsoft.DataLakeStore/accounts" -RoleDefinitionName "Data Lake Analytics Developer"
# Data Warehouse  
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-DW" `
-ResourceType "Microsoft.Sql/servers" -RoleDefinitionName "SQL Server Contributor"
# Existing VNet

# IAAS
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Account Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Blob Data Contributor (Preview)"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"
# Ingest
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Account Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Blob Data Contributor (Preview)"

# PAAS 
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Account Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.StreamAnalytics/streamingjobs" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.EventHub/namespaces" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-RoleDefinitionName "Logic App Contributor"


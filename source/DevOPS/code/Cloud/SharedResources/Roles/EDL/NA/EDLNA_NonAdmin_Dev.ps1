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
<#
G-AM-EDLNADev_DTC  8c56eed4-669b-45b8-b88b-d238a92a4071
G-AM-EDLNADev_CsMkt  2402b726-9985-4d65-b7b3-7ab358396562
G-AM-EDLNADev_Fin  69b1b932-ef7b-49da-86cb-327155b5767f

G-AP-EDLNADev_DTC  5ec0d423-825a-477a-b1c3-3e161ea61473
G-AP-EDLNADev_CsMkt  8472a177-09fb-4974-b141-b610f3862289
G-AP-EDLNADev_Fin  02796649-b7cf-4846-a2e7-f9e712fe79fe
#>
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

# ASE 

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Reader"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Website Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Reader"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Website Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-ASE" `
-RoleDefinitionName "Website Contributor"


# IAAS
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Reader"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-IAAS" `
-RoleDefinitionName "Reader"


# Ingest
Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-Ingest" `
-RoleDefinitionName "Reader"


# PAAS 

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.StreamAnalytics/streamingjobs" -RoleDefinitionName "Contributor"

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.EventHub/namespaces" -RoleDefinitionName "Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-RoleDefinitionName "Reader" -ErrorAction SilentlyContinue

Assign-RoleDefinition -PrincipalId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"

New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-EDLNA-PAAS" `
-RoleDefinitionName "Reader"


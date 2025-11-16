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
G-AM-EDLNADev_DTC  00000000-0000-0000-0000-000000000000
G-AM-EDLNADev_CsMkt  00000000-0000-0000-0000-000000000000
G-AM-EDLNADev_Fin  00000000-0000-0000-0000-000000000000

G-AP-EDLNADev_DTC  00000000-0000-0000-0000-000000000000
G-AP-EDLNADev_CsMkt  00000000-0000-0000-0000-000000000000
G-AP-EDLNADev_Fin  00000000-0000-0000-0000-000000000000
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


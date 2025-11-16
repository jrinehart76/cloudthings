param (
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	[parameter(Mandatory=$true)]
	$Region,
	[string]
	[parameter(Mandatory=$true)]
	$Environment,
	[string]
	[parameter(Mandatory=$true)]
	$LogicAppSPNAppID
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



$PrincipalID = @()
$PrincipalID += (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalAdmin')[0].Id


# Keyvault Access Policies
write-host 'a'
$allKeyvaults = "AKV-AM-EUS-QA-DLG","AKV-AM-EUS-QA-DLG-DTC","AKV-AM-EUS-QA-DLG-Fin","AKV-AM-EUS-QA-DLG-HR","AKV-AM-EUS-QA-DLG-Mkt","AKV-AM-EUS-QA-DLG-SC","AKV-AM-EUS-QA-DLG-Fnd","AKV-AM-EUS-QA-DLG-EDL"
$keyvaultRG = "RG-AM-EastUS-QA-DLG-OtherPAAS"
write-host 'b'
#set contributor access policies for all vaults
foreach($k in $allKeyvaults){
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-CloudOps')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-CloudManagedServices')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalAdmin')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
}
write-host 'c'
#set read access policies for non admin groups 
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_All')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_Fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_DTC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_HR')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_SC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_CsMkt')[0].Id -PermissionsToSecrets get,list

Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_All')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_Fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_DTC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_HR')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_SC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_CsMkt')[0].Id -PermissionsToSecrets get,list

Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fin" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_Fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-DTC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_DTC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Mkt" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_CsMkt')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-SC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_SC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-HR" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalQA_HR')[0].Id -PermissionsToSecrets get,list

# grant datafactory rights to their respective keyvaults
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fin" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-DTC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-dtc')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-MKT" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-mkt')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-SC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-sc')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-HR" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-hr')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-QA-DLG-Fnd" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADServicePrincipal -DisplayName 'df-am-eus-qa-dlg-fnd')[0].Id -PermissionsToSecrets get,list



foreach($p in $PrincipalId){


<# ASE 
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Web Plan Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Website Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Logic App Contributor"
#>


# SQL 
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-ResourceType "Microsoft.Sql/servers" -RoleDefinitionName "SQL Server Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-RoleDefinitionName "Reader"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


# Storage
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-DataStorage" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


# DataFactory
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-RoleDefinitionName "Contributor"



# Servers
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Servers" `
-RoleDefinitionName "Reader"


# KeyVaults (OtherPaaS) 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-OtherPAAS" `
-RoleDefinitionName "Reader"


# DataBrick
#New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-DataBrick" `
#-RoleDefinitionName "Reader"

New-AzRoleAssignment -PrincipalId "b1d6dada-f046-4e18-b489-94c1016bb9b3" -ResourceGroupName "RG-AM-EastUS-NonProd-DLG-DataBrick" `
-ResourceType "Microsoft.Databricks/workspaces" -RoleDefinitionName "Contributor" -ResourceName 'databrick-am-eastus-nonprod-dlg'

}


# Logic App PermissionsToSecrets
#$LogicAppSPNAppID = "32508991-e4a9-4788-b261-6d67e649cdd2"

#New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
#-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Servers" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-DataStorage" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-OtherPaaS" `
-RoleDefinitionName "Reader"


#New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-DataBrick" `
#-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-RoleDefinitionName "Data Factory Contributor"

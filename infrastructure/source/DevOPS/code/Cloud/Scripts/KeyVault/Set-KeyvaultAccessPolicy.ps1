#############################################################################################
#                               Set Key Vault Access Policies                               #
#############################################################################################

param (
    [parameter(Mandatory=$true)][string]$ResourceGroup,
    [parameter(Mandatory=$true)][string]$KeyVaultName,
    [parameter(Mandatory=$true)][string]$AdminADGroup,
    [parameter(Mandatory=$true)][string]$NonAdminADGroup,
	[parameter(Mandatory=$true)][string]$VSTSSpnName
)


# cloudops group perms - Customer-CloudOps
Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ObjectId (Get-AzADGroup -SearchString 'U-Customer-CloudOps')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ObjectId (Get-AzADGroup -SearchString 'U-Customer-CloudManagedServices')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore

# VSTS SPN Rights
Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ObjectId (Get-AzADServicePrincipal -DisplayName $VSTSSpnName)[0].Id -PermissionsToSecrets get,list,set,delete

# admin group perms
If($AdminADGroup -ne "NA"){
    Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ObjectId (Get-AzADGroup -SearchString $AdminADGroup)[0].Id  -PermissionsToSecrets get,list,set,delete
}Else{
    write-host 'No Admin Group Provided'
}
# nonadmin group perms
If($NonAdminADGroup -ne "NA"){
    Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ObjectId (Get-AzADGroup -SearchString $NonAdminADGroup)[0].Id  -PermissionsToSecrets get,list
}Else{
    write-host 'No Non Admin Group Provided'
}

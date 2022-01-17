Param(
    [parameter(Mandatory=$true)][string]$Location,
	[parameter(Mandatory=$true)][string]$Region,
	[parameter(Mandatory=$true)][string]$Application,
	[parameter(Mandatory=$true)][string]$Environment,
    [parameter(Mandatory=$false)][string]$MgmtRG

)

# Get MGMT resource group, then get all keyvaults from MGMT resource group. Check to see if override parameter was supplied.
if (!($MgmtRG)) {
$MgmtRG = (Get-AzResourceGroup -Name "RG-$region-$location*-MGMT").ResourceGroupName
}
$MgmtKeyVault = (Get-AzResource -ResourceType 'Microsoft.KeyVault/vaults' -ResourceGroupName $MgmtRG -Name *).Name

<#
IfElse Logic

If Mgmt keyvault Exists, Get Secrets
-If Secrets Exist Continue
-If Public Key exists and not private, stop
-Else Generate SSH Keys & add to keyvault
Else Mgmt Keyvault Doesn't exist, stop
#>

$PublicKeySecretName = "SSHKey-Public-AKS-$Region-$Location-$Environment-$Application"
$PrivateKeySecretName = "SSHKey-Private-AKS-$Region-$Location-$Environment-$Application"


if($MgmtKeyVault)
{ 
    
    $secretExists1 = Get-AzKeyVaultSecret -VaultName $MgmtKeyVault -Name $PublicKeySecretName
    $secretExists2 = Get-AzKeyVaultSecret -VaultName $MgmtKeyVault -Name $PrivateKeySecretName


    If($secretExists1 -and $secretExists2){
        Write-Host "The secret $PublicKeySecretName and $PrivateKeySecretName already exist. Deployment will continue with using this ssh key"
    }elseif($secretExists1 -and $secretExists2 -eq $null){
        $ErrorActionPreference = "Stop"
        Write-Error "$PublicKeySecretName was located, but the private key $PrivateKeySecretName was not found."
    }else{

        $sshKeyName = "SSHKey-AKS-$Region-$Location-$Environment-$Application"
        ssh-keygen -b 4096 -t rsa -f D:\a\r1\a\$sshKeyName -q -P """"
        
        (gc D:\a\r1\a\$sshKeyName.pub) | ? {$_.trim() -ne "" } | set-content D:\a\r1\a\$sshKeyName.pub
        $content = [System.IO.File]::ReadAllText("D:\a\r1\a\$sshKeyName.pub")
        $content = $content.Trim()
        [System.IO.File]::WriteAllText("D:\a\r1\a\$sshKeyName.pub", $content)

        (gc D:\a\r1\a\$sshKeyName) | ? {$_.trim() -ne "" } | set-content D:\a\r1\a\$sshKeyName
        $content = [System.IO.File]::ReadAllText("D:\a\r1\a\$sshKeyName")
        $content = $content.Trim()
        [System.IO.File]::WriteAllText("D:\a\r1\a\$sshKeyName", $content)




        $PubKey = ConvertTo-SecureString (Get-Content  D:\a\r1\a\$sshKeyName.pub -Raw) -force -AsPlainText
        $PrivKey = ConvertTo-SecureString (Get-Content  D:\a\r1\a\$sshKeyName -Raw) -force -AsPlainText
        Set-AzKeyVaultSecret -VaultName $MgmtKeyVault -SecretName $PublicKeySecretName -SecretValue $PubKey
        Set-AzKeyVaultSecret -VaultName $MgmtKeyVault -SecretName $PrivateKeySecretName -SecretValue $PrivKey

    }
}
else{
    $ErrorActionPreference = "Stop"
    Write-Error "$MgmtKeyVault does not exist"
}


#### Create VSTS Variables

Write-Output "##vso[task.setvariable variable=AKSPublicSSHKey]`$($($PublicKeySecretName))"
Write-Output "##vso[task.setvariable variable=MgmtKeyvault]$($MgmtKeyVault)"

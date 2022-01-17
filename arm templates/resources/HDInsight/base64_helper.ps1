## when you need to pull the cert and password from keyvault, this script may help.  

# variables
$vaultName = "AKV-AM-EastUS-DevOps-POC"
$certificateName = 'elc10mHdiTemplate'
$secretName = "elc10mHdiTemplate-pfx"
$password = '7F1R&vYLIegy71*t'  # this is the cert password.  This can also be generated from keyvault if desired
$pfxPath = "C:\Users\dave\Downloads\akv-am-eastus-devops-poc-elc10mHdiTemplate-withpassword.pfx"
$pfxBaseSixtyFour = "C:\Users\dave\Downloads\pfx_with_password.txt"

# pull the pfx directly from keyvault
Login-AzureRmAccount
Get-AzureRmSubscription
Set-AzureRmContext  -SubscriptionId 

$kvSecret = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $certificateName
$kvSecretBytes = [System.Convert]::FromBase64String($kvSecret.SecretValueText)
$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certCollection.Import($kvSecretBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)


#Get the pfx created and apply the password
$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
[System.IO.File]::WriteAllBytes($pfxPath, $protectedCertificateBytes)

#test that the password works, this should show the thumbprint
Get-PfxCertificate -FilePath $pfxPath

# now get a Base64 version of the pfx to pass into the ARM template
$fc_bytes = get-content $pfxPath -Encoding Byte
[System.Convert]::ToBase64String($fc_bytes) | Out-File $pfxBaseSixtyFour

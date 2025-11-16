$subscription = "CUST-A-AM-CEPLATAM"
$keyVaultName = "AKV-AM-EastUS-DEV-CEP"
$certificateName = "CUST-A-cep-api-am-dev-customer-a-domain-com"
$pfxPassword = "YourSecurePasswordHere"
$exportPath = ".\Scripts\KeyVault"
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subscription -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

$kvSecret = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $certificateName
$kvSecretBytes = [System.Convert]::FromBase64String($kvSecret.SecretValueText)
$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certCollection.Import($kvSecretBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $pfxPassword)
$pfxPath = $exportPath.TrimEnd("\") + "\$($certificateName).pfx"
[System.IO.File]::WriteAllBytes($pfxPath, $protectedCertificateBytes)
Param(
    [parameter(Mandatory=$true)][string]$KeyVaultName,
	[parameter(Mandatory=$true)][string]$AppName,
	[parameter(Mandatory=$true)][string]$KeyVaultSubscription,
	[parameter(Mandatory=$true)][string]$SvcAcctPass
)
Select-AzSubscription -Subscription $KeyVaultSubscription

# authenticate
# $Username = "SVC-ServicePrincipalCreator@elcompanies.onmicrosoft.com"
$Username = "SA-AM-svc-azspncreat@am.elcompanies.net"
$securePassword = ConvertTo-SecureString -String $SvcAcctPass -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$securePassword
Connect-AzAccount -Credential $Credentials

$startDate = get-date
$endDate = (get-date).AddYears(1)
$spn = Get-AzADApplication -DisplayName $appName

if(Get-AzADApplication -DisplayName $appName)
{ 
    $secretName = "$($appName)-----$($spn.ApplicationId)"
    write-host "A Service Principal with the name $appName already exists, validating key vault entry."
    $secretExists = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $secretName

    If($secretExists -eq $null){
        $ErrorActionPreference = "Stop"
        Write-Error "The Service Principal Exists, but there is not a corresponding secret with with value $($appName)------$($spn.ApplicationId)."
    }else{
        Write-Host "The secret $($appName)------$($spn.ApplicationId) was found in the keyvault."
    }
}
else{
	$spn = New-AzADServicePrincipal -DisplayName $AppName -StartDate $startDate -EndDate $endDate
	$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($spn.Secret)
	$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    Write-Host "`n############################################################"
    Write-Host "AppName = $($appName)"
    Write-Host "servicePrincipalAppId: $($spn.ApplicationId)"
    Write-Host "############################################################`n"
    
    $secretName = "$($appName)-----$($spn.ApplicationId)"
    $Exists = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $secretName

    if($Exists -eq $null){
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $secretName -SecretValue $spn.Secret

	    Write-Host "`n############################################################"
	    Write-Host "AKV Name: $($KeyVaultName)"
	    Write-Host "AKV Secret Name: $($appName)------$($spn.ApplicationId)"
	    Write-Host "############################################################`n"
    }else{ 
	    write-host "$secretName already exists" -BackgroundColor Black -ForegroundColor Green 
    }
}

#### Create VSTS Variables
$displayName = $spn.DisplayName
$appId = $spn.ApplicationId

Write-Output "##vso[task.setvariable variable=AKSServicePrincipalAppID]$($appId)"
Write-Output "##vso[task.setvariable variable=AKSServicePrincipalAppIDKey]`$($($secretName))"

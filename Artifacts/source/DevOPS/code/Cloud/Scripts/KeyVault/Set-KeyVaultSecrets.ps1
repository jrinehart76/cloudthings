#############################################################################################
#                                  Set Key Vault Secrets                                    #
#############################################################################################



Param(
    [parameter(Mandatory=$true)][string]$KeyVaultName,
    [parameter(Mandatory=$true)][array]$KeyVaultSecrets,
	[parameter(Mandatory=$true)][int]$PasswordLength

)


# Random Password Generator Function
function New-RandomPassword {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [int]
        $PasswordLength,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeLowerCase,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeUpperCase,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeNumbers,

        [Parameter(Mandatory = $false)]
        [switch]
        $IncludeSpecialChar
    )

    Write-Verbose "Generating random password"
    $upperArray = [char]'A' .. [char]'Z' | ForEach-Object {[char]$_}
    $lowerArray = [char]'a' .. [char]'z' | ForEach-Object {[char]$_}
    $nums = 0 .. 9 | ForEach-Object { $_.ToString()}
    $special = "!$%@#"
    $finalCharset = ""
    $password = ""
   
    if ($IncludeLowerCase) {
        Write-Verbose "Including lower case"
        $finalCharset += $lowerArray -join ""
    }

    if ($IncludeUpperCase) {
        Write-Verbose "Including upercase case"
        $finalCharset += $upperArray -join ""
    }

    if ($IncludeNumbers) {
        Write-Verbose "Including numbers"
        $finalCharset += $nums -join ""
    }

    if ($IncludeSpecialChar) {
        Write-Verbose "Including special characters"
        $finalCharset += $special
    }

    for ($i = 0; $i -lt $PasswordLength; $i++) {
        $cIndex = Get-Random -Maximum $finalCharset.Length
        $password += $finalCharset[$cIndex]
    }

    Write-Verbose "Password generated: $($password)"
    return $password
}

$includeLowerCase = $true
$includeUpperCase = $true
$includeNumbers = $true
$includeSpecialChar = $true

Add-Type -Assembly System.Web

foreach($s in $KeyVaultSecrets){
	$password = New-RandomPassword `
		-PasswordLength $passwordLength `
		-IncludeLowerCase:$includeLowerCase `
		-IncludeUpperCase:$includeUpperCase `
		-IncludeNumbers:$includeNumbers `
		-IncludeSpecialChar:$includeSpecialChar `
		-Verbose:$verboseOutput
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $Exists = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $s

    if($Exists -eq $null){
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $s -SecretValue $securePassword
    }else{ write-host "$s already exists" -BackgroundColor Black -ForegroundColor Green }
}



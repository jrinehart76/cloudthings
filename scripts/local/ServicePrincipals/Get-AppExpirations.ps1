$csvFile = "%USERPROFILE%\Documents\AppExpirations.csv"
$verboseOutput = $true

##################################
$results = @()
$date = Get-Date
$90days = (Get-Date).AddDays(90)
$apps = Get-AzADApplication

foreach ($app in $apps) {
    Write-Verbose $app.DisplayName -Verbose:$verboseOutput
    $owner = Get-AzADSpCredential -ObjectId $app.ObjectID
    $app.PasswordCredentials | % {
        $expired = $false
        $expires90days = $false
        if ($_.EndDate -gt $date -and $_.EndDate -lt $90days) {
            $expires90days = $true
        }
        elseif ($_.EndDate -le $date) {
            $expired = $true
        }
        $results += [PSCustomObject] @{
            "CredentialType" = "PasswordCredentials"
            "DisplayName"    = $app.DisplayName
            "Expired"        = $expired
            "Expires90Days"  = $expires90days
            "ExpiryDate"     = $_.EndDate
            "StartDate"      = $_.StartDate
            "KeyID"          = $_.KeyId
            "Owners"         = $owner.UserPrincipalName
            "AppId"          = $app.AppId
            "ObjectId"       = $app.ObjectId
        }
    } 
        
    $app.KeyCredentials | % {
        $expired = $false
        $expires90days = $false
        if ($_.EndDate -gt $date -and $_.EndDate -lt $90days) {
            $expires90days = $true
        }
        elseif ($_.EndDate -le $date) {
            $expired = $true
        }
        $results += [PSCustomObject] @{
            "CredentialType" = "KeyCredentials"
            "DisplayName"    = $app.DisplayName
            "Expired"        = $expired
            "Expires90Days"  = $expires90days
            "ExpiryDate"     = $_.EndDate
            "StartDate"      = $_.StartDate
            "KeyID"          = $_.KeyId
            "Owners"         = $owner.UserPrincipalName
            "AppId"          = $app.AppId
            "ObjectId"       = $app.ObjectId
        }
    }                            
}

$results | Export-Csv $csvFile -NoTypeInformation
Write-Output "`nResults output to $($csvFile)`n"
param(
    [Parameter(Mandatory = $true)]
    [String]$rgName,

    [Parameter(Mandatory = $true)]
    [String]$autoAccount,

    [Parameter(Mandatory = $false)]
    [String]$subId = (Get-AzContext).Subscription.Id
)

function Get-AzCachedAccessToken() {
    if (-not (Get-Module Az.Accounts)) {
        Import-Module Az.Accounts
    }
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if (-not $azProfile.Accounts.Count) {
        Write-Error "Ensure you have logged in before calling this function."    
    }
  
    $currentAzureContext = Get-AzContext
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
    $token.AccessToken
}

function Get-AzBearerToken() {
    ('Bearer {0}' -f (Get-AzCachedAccessToken))
}

$uri = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.Automation/automationAccounts/$autoAccount/softwareUpdateConfigurations?api-version=2017-05-15-preview"

$headers = @{
    Authorization = Get-AzBearerToken
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $updateConfiguration = $response.value
    #$updateConfiguration | Export-Csv -Path "$([environment]::GetFolderPath("mydocuments"))\UpdateManagementList.csv" -NoTypeInformation
}
catch {
    $description = $_.Exception.Response.StatusDescription
    Write-Host "Error: $description" -ForegroundColor Red
}

$outFile = "$([environment]::GetFolderPath("mydocuments"))\UpdateManagementList.csv"
if (Test-Path $outFile) {
    Remove-Item $outFile
}

foreach ($config in $updateConfiguration) {
    $vms = @()
    $nonaz = @()

    $vms = $config.properties.updateconfiguration.azurevirtualmachines
    $nonaz = $config.properties.updateconfiguration.nonazurecomputernames
    $os = $config.properties.updateConfiguration.operatingSystem

    $output = $vms | ForEach-Object { 
        $vmarr = @()
        $vmarr = $_.split('/')
        $vmname = $vmarr | Select-Object -Last 1
        $sub = $vmarr | Select-Object -Index 2
        $subInfo = Get-AzSubscription -SubscriptionId $sub -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $rg = $vmarr | Select-Object -Index 4
        
        if ($nonaz -match $vmname) { $nonazfound = "yes" }
        else { $nonazfound = "no" }

        [PSCustomObject]@{   
            "VM Name"                    = $vmname
            "Subscription Name"          = $subInfo.Name
            "Subscription ID"            = $sub
            "Resource Group"             = $rg
            "Operating System"           = $os
            "Update Config Name"         = $config.Name
            "Frequency"                  = $config.properties.Frequency
            "Next Run"                   = $config.properties.nextRun
            "Provisioning State"         = $config.properties.provisioningState
            "Pre-Task"                   = $config.properties.tasks.preTask
            "Post-Task"                  = $config.properties.tasks.postTask
            "Non-Azure Computer Name"    = $nonazfound
        }
    }
    $output | Export-Csv -Path $outFile -delimiter ";" -Append -force -notypeinformation
}

"
Update Management report written to $outFile
"
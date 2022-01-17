$subName = "GCCS"
$verboseOutput = $false

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

foreach ($resourceProvider in (Get-AzureRmResourceProvider -Verbose:$verboseOutput)) {
    Write-Output "`n$($resourceProvider.ProviderNamespace)"
    Write-Output "------------------------------"
    foreach ($resourceType in $resourceProvider.ResourceTypes) {
        Write-Output "`t$($resourceType.ResourceTypeName)"
        foreach ($apiVersion in $resourceType.ApiVersions) {
            Write-Output "`t`t$($apiVersion)"
        }
    }
}



<#
    .DESCRIPTION
        Creates CSV file containing resources and their respective tags

    .PREREQUISITES

    .Example
        
    .TODO
        System paths instead of direct folder/file
        Variables for column headers
        Comments

    .NOTES
        AUTHOR: MSP Ops Team
        LASTEDIT: May 22, 2019

    .VERSION
        1.0 - initial release

    .CHANGELOG
#>

$subscriptions = Get-AzSubscription

"ResourceName,ResourceGroupName,ApplicationOwner,BusinessOwner,ApplicationName,FiscalYear" | Out-File -FilePath C:\Users\JasonRinehart\Documents\tagging-temp.csv

foreach ($sub in $subscriptions) {
    Set-AzContext $sub.Id
    $subName = $sub.Name
    $resources = Get-AzResource -ExpandProperties

    $resources `
    | Select-Object ResourceName, ResourceGroupName, @{n="ApplicationOwner"; e={$_.tags["ApplicationOwner"]}}, @{n="BusinessOwner"; e={$_.tags["BusinessOwner"]}}, @{n="ApplicationName"; e={$_.tags["ApplicationName"]}}, @{n="FiscalYear"; e={$_.tags["FiscalYear"]}} `
    | Export-Csv -Path "C:\Users\JasonRinehart\Documents\tagging-temp.csv" -NoTypeInformation

    Import-Csv "C:\Users\JasonRinehart\Documents\tagging-temp.csv" `
    | Select-Object *,@{n='SubscriptionName';e={$($subName)}} `
    | Export-Csv -NoTypeInformation -Append -Path "C:\Users\JasonRinehart\Documents\tag_list.csv"
}
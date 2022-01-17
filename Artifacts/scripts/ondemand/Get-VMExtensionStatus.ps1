<#
    .DESCRIPTION
       
    .PREREQUISITES
      
    .EXAMPLE

    .TO-DO
      
    .NOTES
        AUTHOR(s): Erlin Tego

    .VERSION

    .CHANGELOG  
#>

$VMEs = @()
$output = @()
$subList = Get-AzSubscription

foreach ($sub in $subList) {
    Set-AzContext -Subscription $sub.Name
    $vms = Get-AzVM
    foreach ($vm in $vms) {
        #get all extensions regardless of status
        $vmes = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        #if extensions are null
        if (!($vmes)) {
            Write-Output "Extension not found for [$($vm.Name)]"
            $output = $_.vms | ForEach-Object { 
                [PSCustomObject]@{   
                    "VM Name"                    = $vm.Name
                    "Resource Group"             = $vm.ResourceGroupName
                    "Extention Type"             = "Not Installed" 
                    "Extension Name"             = "Missing"
                    "Version"                    = "Missing"
                    "Provisioning State"         = "Missing" 
                    "Auto Upgrade Minor Version" = "Missing" -join ','
                }
            }
            $output | Export-Csv -Path "$([environment]::GetFolderPath("mydocuments"))\VMExtensionAuditOnDemand.csv" -delimiter ";" -Append -force -notypeinformation
        }
        #if extensions are not null
        if ($vmes) {
            foreach ($vme in $vmes) {
                Write-Output "Extension found for [$($vm.Name)]"
                $output = $vme | ForEach-Object { 
                    [PSCustomObject]@{
                        "VM Name"                    = $vme.VMName
                        "Resource Group"             = $vme.ResourceGroupName
                        "Extention Type"             = $vme.ExtensionType
                        "Extension Name"             = $vme.Name
                        "Version"                    = $vme.Version
                        "Provisioning State"         = $vme.ProvisioningState
                        "Auto Upgrade Minor Version" = $vme.AutoUpgradeMinorVersion -join ','
                    } 
                }
                $output | Export-Csv -Path "$([environment]::GetFolderPath("mydocuments"))\VMExtensionAuditOnDemand.csv" -delimiter ";" -Append -force -notypeinformation
            }
        }
    }
    Write-Output ""
}
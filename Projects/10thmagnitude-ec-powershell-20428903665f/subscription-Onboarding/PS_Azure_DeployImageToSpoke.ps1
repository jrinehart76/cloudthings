<#
.SYNOPSIS
  Deploy Ecolab Standard Server image to a spoke subscription.

.DESCRIPTION
  This script will create a snapshot of the standard syspreped OS image disk on the hub, copy it to the spoke subscription
  and then create an Azure image object for all the regions specified on the input variable.

.REQUIREMENTS
    - Existing syspreped managed disk image on the ITS-Shared hub.
    - Standard Cloud Team Azure Resource Groups per region (i.e. <Sub>-CLOUD-001-<P/NP> on "East US 2")

.NOTES
  Version:        1.0
  Author:         Marcelo Zingman
  Creation Date:  1/24/2018
  Purpose/Change: Initial script development
#>


#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Login-AzureRmAccount

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$targetSubscriptionName = "ITS-PROD"

$imageDiskName = "2012r2STDv20180117SYSPREPED-osDisk"
$imageName = "ECL-W2K12R2STD-20180117-IMG"
$regions = "centralus","eastus2"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

if ($targetSubscriptionName.EndsWith("NONP")) {
    $suffix = "NP"
}
elseIf ($targetSubscriptionName.EndsWith("PROD")) {
    $suffix = "P"
}

foreach ($region in $regions) {

    Switch ($region) {

            "centralus" {
                $hubResourceGroupName = "ITS-CLOUD-001-P"
                $targetResourceGroupName = $targetSubscriptionName.Substring(0,3) + "-CLOUD-001-" + $suffix
            }
            "eastus2" {
                $hubResourceGroupName = "ITS-CLOUD-002-P"
                $targetResourceGroupName = $targetSubscriptionName.Substring(0,3) + "-CLOUD-002-" + $suffix
            }
    }
    
    <#-- Create a snapshot of the OS disk from the Hub --#>

    Select-AzureRmSubscription -SubscriptionId 10415657-439e-45ad-884e-52904a1679cd #ITS-Shared context


    $disk = Get-AzureRmDisk -ResourceGroupName $hubResourceGroupName -DiskName $diskName
    $snapshot = New-AzureRmSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $region
 
    $snapshotName = $imageName + "-$region-snap"
 
    $snapHub = New-AzureRmSnapshot -ResourceGroupName $hubResourceGroupName -Snapshot $snapshot -SnapshotName $snapshotName


    <#-- Copy the snapshot from the hub to the target spoke --#>

    Select-AzureRmSubscription -SubscriptionId (Get-AzureRmSubscription -SubscriptionName $targetSubscriptionName).Id 

    $snapshotConfig = New-AzureRmSnapshotConfig -OsType Windows `
                                                -Location $region `
                                                -CreateOption Copy `
                                                -SourceResourceId $snapHub.Id
 
    $targetSnap = New-AzureRmSnapshot -ResourceGroupName $targetResourceGroupName `
                                      -SnapshotName $snapshotName `
                                      -Snapshot $snapshotConfig


    <#-- Create a new Image on the target spoke from the copied snapshot --#>
 
    $imageConfig = New-AzureRmImageConfig -Location $region
 
    Set-AzureRmImageOsDisk -Image $imageConfig `
                           -OsType Windows `
                           -OsState Generalized `
                           -SnapshotId $targetSnap.Id
 
    $targetImage = New-AzureRmImage -ResourceGroupName $targetResourceGroupName `
                                    -ImageName $imageName `
                                    -Image $imageConfig

    
    <#-- Clean up the snapshots from the hub and spoke --#>

    Remove-AzureRmSnapshot -ResourceGroupName $targetResourceGroupName -SnapshotName $snapshotName -force
 
    Select-AzureRmSubscription -SubscriptionId 10415657-439e-45ad-884e-52904a1679cd #ITS-Shared context
    Remove-AzureRmSnapshot -ResourceGroupName $hubResourceGroupName -SnapshotName $snapshotName -force
}
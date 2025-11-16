Param(
    [parameter(Mandatory=$true)][string]$ServerOS
)

switch ($ServerOS) {
   "Windows2012"  {$image = 'SharedImage-AM-EastUS-SS-WindowsServer-2012R2'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-WindowsServer-2012R2'; break}
   "Windows2016"  {$image = 'SharedImage-AM-EastUS-SS-WindowsServer-2016'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-WindowsServer-2016'; break}
   "Windows2019"  {$image = 'SharedImage-AM-EastUS-SS-WindowsServer-2019'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-WindowsServer-2019'; break}
   "Ubuntu1604"  {$image = 'SharedImage-AM-EastUS-SS-Ubuntu-1604'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-Ubuntu-1604'; break}
   "Ubuntu1804"  {$image = 'SharedImage-AM-EastUS-SS-Ubuntu-1804'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-Ubuntu-1804'; break}
   "RHEL74"  {$image = 'SharedImage-AM-EastUS-SS-RHEL-74'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-RHEL-74'; break}
   "RHEL76"  {$image = 'SharedImage-AM-EastUS-SS-RHEL-76'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-RHEL-76'; break}
   "CentOS75"  {$image = 'SharedImage-AM-EastUS-SS-CentOS-75'; $ImageVersion = Get-AzGalleryImageVersion -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' -GalleryImageDefinitionName 'SharedImage-AM-EastUS-SS-CentOS-75'; break}
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$ServerOS is not valid. Allowed Values are Windows2012, Windows2016, Windows2019, Ubuntu1604, Ubuntu1804, RHEL74, RHEL76, CentOS75"
   }
}

$ImageVersionFormatted = ($ImageVersion | Select-Object -Last 1 | ft name -HideTableHeaders |Out-String).trim()

# Creates and Sets service endpoint variable
Write-Output "##vso[task.setvariable variable=SharedImage]$($image)"
Write-Output "##vso[task.setvariable variable=SharedImageVersion]$($ImageVersionFormatted)"


<# Get Image Definition
Get-AzGalleryImageDefinition -ResourceGroupName 'rg-region1-ss-images' -GalleryName 'sharedimagegalleryameastusss' | ft name
#>
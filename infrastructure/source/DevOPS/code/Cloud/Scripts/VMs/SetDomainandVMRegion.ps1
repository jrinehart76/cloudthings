###############################################################
#  Sets Domain, VMRegion, AvSet Update and Fault Domains, OU
###############################################################


Param(
    [parameter(Mandatory=$true)][string]$Location
)

switch ($Location) {
   "EastUS" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=am,DC=elcompanies,DC=net"; $Domain = "am.elcompanies.net"; $VMRegion = "US"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 3; break}
   "WestUS" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=am,DC=elcompanies,DC=net"; $Domain = "am.elcompanies.net"; $VMRegion = "US"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 3; break}
   "SoutheastAsia" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=elcompanies,DC=net"; $Domain = "ap.elcompanies.net"; $VMRegion = "SG"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "UKSouth" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=eu,DC=elcompanies,DC=net"; $Domain = "eu.elcompanies.net"; $VMRegion = "UK"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "ChinaEast2" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=elcompanies,DC=net"; $Domain = "ap.elcompanies.net"; $VMRegion = "CN"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "KoreaCentral" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=elcompanies,DC=net"; $Domain = "ap.elcompanies.net"; $VMRegion = "KR"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Location is not valid or does not have a matching service endpoint"
   }
}
    
Write-Host "OU: $OU"
Write-Host "Domain: $Domain"
Write-Host "VM Region: $VMRegion"
Write-Host "AvSet Update Domain Count: $availabilitySetUpdateDomainCount"
Write-Host "AvSet Fault Domain Count:$availabilitySetFaultDomainCount"


Write-Output "##vso[task.setvariable variable=OU]$($OU)"
Write-Output "##vso[task.setvariable variable=Domain]$($Domain)"
Write-Output "##vso[task.setvariable variable=VMRegion]$($VMRegion)"
Write-Output "##vso[task.setvariable variable=AvailabilitySetUpdateDomainCount]$($availabilitySetUpdateDomainCount)"
Write-Output "##vso[task.setvariable variable=AvailabilitySetFaultDomainCount]$($availabilitySetFaultDomainCount)"


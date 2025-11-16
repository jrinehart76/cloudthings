###############################################################
#  Sets Domain, VMRegion, AvSet Update and Fault Domains, OU
###############################################################


Param(
    [parameter(Mandatory=$true)][string]$Location
)

switch ($Location) {
   "EastUS" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=am,DC=customer-a-domain,DC=net"; $Domain = "am.customer-a-domain.local"; $VMRegion = "US"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 3; break}
   "WestUS" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=am,DC=customer-a-domain,DC=net"; $Domain = "am.customer-a-domain.local"; $VMRegion = "US"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 3; break}
   "SoutheastAsia" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=customer-a-domain,DC=net"; $Domain = "ap.customer-a-domain.local"; $VMRegion = "SG"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "UKSouth" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=eu,DC=customer-a-domain,DC=net"; $Domain = "eu.customer-a-domain.local"; $VMRegion = "UK"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "ChinaEast2" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=customer-a-domain,DC=net"; $Domain = "ap.customer-a-domain.local"; $VMRegion = "CN"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
   "KoreaCentral" {$OU = "OU=Managed Azure,OU=Azure,OU=CUST-A Servers,DC=ap,DC=customer-a-domain,DC=net"; $Domain = "ap.customer-a-domain.local"; $VMRegion = "KR"; $availabilitySetUpdateDomainCount = 5; $availabilitySetFaultDomainCount = 2; break}
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


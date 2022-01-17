Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "ELC-PROD-LEARN" {$VSTSSpnName = ""; Break}           
    "ELC-AP-PROD-V2" {$VSTSSpnName = ""; Break}           
    "ELC-AM-POC-DevOps" {$VSTSSpnName = ""; Break}       
    "ELC-AP-NONPROD-V2" {$VSTSSpnName = ""; Break}       
    "ELC-AM-PROD" {$VSTSSpnName = ""; Break}               
    "ELC-EU-PROD-V2" {$VSTSSpnName = ""; Break}           
    "ELC-AM-PROD-PAAS" {$VSTSSpnName = ""; Break}        
    "ELC-NONPROD-LEARN" {$VSTSSpnName = ""; Break} 
    "ELC-AM-NONPROD-PAAS" {$VSTSSpnName = ""; Break}
    "ELC MyELX" {$VSTSSpnName = ""; Break}
    "ELC-EU-NONPROD-V2" {$VSTSSpnName = ""; Break} 
    "ELC-EU-NONPROD" {$VSTSSpnName = ""; Break}
    "ELC-AP-NONPROD" {$VSTSSpnName = ""; Break}     
    "ELC-AM-POC" {$VSTSSpnName = ""; Break}
    "ELC-AM-NONPROD-DATALAKE" {$VSTSSpnName = ""; Break}
    "ELC-AM-NONPROD" {$VSTSSpnName = ""; Break}
    "ELC-AM-CEPLATAM" {$VSTSSpnName = ""; Break}
    "Bobbi Brown" {$VSTSSpnName = ""; Break}
    "MyELC" {$VSTSSpnName = ""; Break}
    "ELC-AM-PUBLIC" {$VSTSSpnName = ""; Break}
    "ELC-NONPROD-SAP" {$VSTSSpnName = ""; Break}
    "ELC-PROD-SAP" {$VSTSSpnName = ""; Break}
    "ELC-AM-PROD-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "ELC-AM-PROD-O9" {$VSTSSpnName = ""; Break}
    "ELC-AM-PROD-CEPLATAM" {$VSTSSpnName = ""; Break}
    "ELC-AM-PROD-DATALAKE" {$VSTSSpnName = ""; Break}
    "ELC-AM-NONPROD-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "ELC-AM-NONPROD-E2E" {$VSTSSpnName = ""; Break}
    "ELC-AM-PROD-E2E" {$VSTSSpnName = ""; Break}
    #"ELC-AM-POC-V2" {$VSTSSpnName = ""; Break}           
    "GCCS" {$VSTSSpnName = ""; Break}      
    #"ELC-AP-PROD" {$VSTSSpnName = ""; Break}
    #"ELC-EU-PROD" {$VSTSSpnName = ""; Break}               
    #"ELC APAC PoC" {$VSTSSpnName = ""; Break}
    #"ELC APAC Public" {$VSTSSpnName = ""; Break}
    #"ELC App Dev Migration" {$VSTSSpnName = ""; Break}
    #"ELC-AM-DR-C2M" {$VSTSSpnName = ""; Break}
    #"ELC-AM-Security-POC" {$VSTSSpnName = ""; Break}
    #"ELC-AP-POC" {$VSTSSpnName = ""; Break}  
    #"ELC-EU-POC" {$VSTSSpnName = ""; Break}
    #"ELC-Windows-Analytics" {$VSTSSpnName = ""; Break}
    #"HCLTools" {$VSTSSpnName = ""; Break}
    #"SAP" {$VSTSSpnName = ""; Break}            
    #"ELC-GLOBAL-OPERATIONS" {{$VSTSSpnName = ""; Break}   
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Subscription is not valid or does not have a VSTS SPN"
   }
}
    
Write-Host $VSTSSpnName

# set vsts variable
Write-Output "##vso[task.setvariable variable=VSTSSpnName]$($VSTSSpnName)"

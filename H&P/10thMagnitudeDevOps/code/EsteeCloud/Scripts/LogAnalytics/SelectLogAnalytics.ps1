Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "ELC-PROD-LEARN" {$LogAnalyticsWorkspace = "la-prod-learn"; $LogAnalyticsResourceGroup ="RG-PROD-LEARN-MGMT"; Break}           
    "ELC-AP-PROD-V2" {$LogAnalyticsWorkspace = "la-ap-southeastasia-prod-v2"; $LogAnalyticsResourceGroup ="RG-AP-SoutheastAsia-Prod-V2-MGMT"; Break}           
    "ELC-AM-POC-DevOps" {$LogAnalyticsWorkspace = "la-am-eastus-devopspoc"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-DevOpsPOC-Mgmt"; Break}       
    "ELC-AP-NONPROD-V2" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod-v2"; $LogAnalyticsResourceGroup ="RG-AP-SoutheastAsia-NONPROD-V2-Mgmt"; Break}       
    "ELC-AM-PROD" {$LogAnalyticsWorkspace = "la-am-eastus-Prod"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Prod-Mgmt"; Break}               
    "ELC-EU-PROD-V2" {$LogAnalyticsWorkspace = "la-eu-uksouth-prod-v2"; $LogAnalyticsResourceGroup ="rg-eu-uksouth-prod-v2-mgmt"; Break}           
    "ELC-AM-PROD-PAAS" {$LogAnalyticsWorkspace = "la-am-eastus-prod-paas"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-paas-mgmt"; Break}         
    "ELC-NONPROD-LEARN" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-learn"; $LogAnalyticsResourceGroup ="rg-nonprod-learn-mgmt"; Break}        
    "ELC-AM-NONPROD-PAAS" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-PaaS"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-paas-mgmt"; Break}       
    "ELC MyELX" {$LogAnalyticsWorkspace = "la-am-eastus-prod-myelx"; $LogAnalyticsResourceGroup ="rg-am-eastus-myelx-mgmt"; Break}                
    "ELC-EU-NONPROD-V2" {$LogAnalyticsWorkspace = "la-eu-uksouth-nonprod-v2"; $LogAnalyticsResourceGroup ="RG-EU-UKSouth-NonProd-V2-MGMT"; Break}        
    "ELC-EU-NONPROD" {$LogAnalyticsWorkspace = "la-eu-weurope-NonProd"; $LogAnalyticsResourceGroup ="RG-EU-UKSouth-NonProd-Mgmt"; Break}           
    "ELC-AP-NONPROD" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod"; $LogAnalyticsResourceGroup ="rg-ap-southeastasia-nonprod-mgmt"; Break}            
    "ELC-AM-POC" {$LogAnalyticsWorkspace = "la-am-eastus-POC"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-POC-Mgmt"; Break}               
    "ELC-AM-NONPROD-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-DataLake"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-DataLake-Mgmt"; Break}  
    "ELC-AM-NONPROD" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-Mgmt"; Break}
    "ELC-AM-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-CEPLATAM"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-CEPLATAM-Mgmt"; Break}          
    "Bobbi Brown" {$LogAnalyticsWorkspace = "la-am-eastus-bobbibrown-mgmt"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-BobbiBrown-Mgmt"; Break}              
    "MyELC" {$LogAnalyticsWorkspace = "la-AM-EastUS-MyELC"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-MyELC-MGMT"; Break}                    
    "ELC-AM-PUBLIC" {$LogAnalyticsWorkspace = "la-am-eastus-Public"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Public-Mgmt"; Break}             
    "ELC-NONPROD-SAP" {$LogAnalyticsWorkspace = "la-nonprod-sap"; $LogAnalyticsResourceGroup ="rg-nonprod-sap-mgmt"; Break}           
    "ELC-PROD-SAP" {$LogAnalyticsWorkspace = "la-prod-sap"; $LogAnalyticsResourceGroup ="rg-prod-sap-mgmt"; Break}             
    "ELC-AM-PROD-CORNERSTONE" {$LogAnalyticsWorkspace = "la-prod-cornerstone"; $LogAnalyticsResourceGroup ="rg-prod-cornerstone-mgmt"; Break}   
    "ELC-AM-PROD-O9" {$LogAnalyticsWorkspace = "la-am-eastus-prod-o9"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-o9-mgmt"; Break}            
    "ELC-AM-PROD-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-Prod-CEPLATAM"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Prod-CEPLATAM-Mgmt"; Break}      
    "ELC-AM-PROD-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-prod-edlna"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-edlna-mgmt"; Break}     
    "ELC-AM-NONPROD-CORNERSTONE" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-cornerstone"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-cornerstone-mgmt"; Break}
    "ELC-AM-NONPROD-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-e2e"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-e2e-mgmt"; Break}  
    "ELC-AM-PROD-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-prod-e2e"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-e2e-mgmt"; Break}
    "ELC-CN-PROD" {$LogAnalyticsWorkspace = "la-cn-chinaeast2-prod"; $LogAnalyticsResourceGroup ="RG-CN-ChinaEast2-Prod-Mgmt"; Break}  
    #"ELC-AM-POC-V2" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}            
    #"GCCS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                      
    #"ELC-AP-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}              
    #"ELC-EU-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                        
    #"ELC APAC PoC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}             
    #"ELC APAC Public" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}          
    #"ELC App Dev Migration" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
    #"ELC-AM-DR-C2M" {$LogAnalyticsWorkspace = "LogAnalytics-AM-EastUS-DR-C2M"; $LogAnalyticsResourceGroup ="rg-am-eastus-dr-c2m-azuremgmt"; Break}            
    #"ELC-AM-Security-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}      
    #"ELC-AP-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"ELC-EU-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"ELC-Windows-Analytics" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}    
    #"HCLTools" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}  
    #"SAP" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                       
    #"ELC-GLOBAL-OPERATIONS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Subscription is not valid or does not have a matching Log Analytics Workspace"
   }
}
    
Write-Host $LogAnalyticsWorkspace
Write-Host $LogAnalyticsResourceGroup

# set vsts variable
Write-Output "##vso[task.setvariable variable=LogAnalyticsWorkspace]$($LogAnalyticsWorkspace)"
Write-Output "##vso[task.setvariable variable=LogAnalyticsResourceGroup]$($LogAnalyticsResourceGroup)"

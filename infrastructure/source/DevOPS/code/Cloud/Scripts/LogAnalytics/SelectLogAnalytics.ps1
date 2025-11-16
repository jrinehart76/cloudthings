Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "CUST-A-PROD-LEARN" {$LogAnalyticsWorkspace = "la-prod-learn"; $LogAnalyticsResourceGroup ="RG-PROD-LEARN-MGMT"; Break}           
    "CUST-A-AP-PROD-V2" {$LogAnalyticsWorkspace = "la-ap-southeastasia-prod-v2"; $LogAnalyticsResourceGroup ="RG-AP-SoutheastAsia-Prod-V2-MGMT"; Break}           
    "CUST-A-AM-POC-DevOps" {$LogAnalyticsWorkspace = "la-am-eastus-devopspoc"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-DevOpsPOC-Mgmt"; Break}       
    "CUST-A-AP-NONPROD-V2" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod-v2"; $LogAnalyticsResourceGroup ="RG-AP-SoutheastAsia-NONPROD-V2-Mgmt"; Break}       
    "CUST-A-AM-PROD" {$LogAnalyticsWorkspace = "la-am-eastus-Prod"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Prod-Mgmt"; Break}               
    "CUST-A-EU-PROD-V2" {$LogAnalyticsWorkspace = "la-eu-uksouth-prod-v2"; $LogAnalyticsResourceGroup ="rg-eu-uksouth-prod-v2-mgmt"; Break}           
    "CUST-A-AM-PROD-PAAS" {$LogAnalyticsWorkspace = "la-am-eastus-prod-paas"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-paas-mgmt"; Break}         
    "CUST-A-NONPROD-LEARN" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-learn"; $LogAnalyticsResourceGroup ="rg-nonprod-learn-mgmt"; Break}        
    "CUST-A-AM-NONPROD-PAAS" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-PaaS"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-paas-mgmt"; Break}       
    "CUST-A MyELX" {$LogAnalyticsWorkspace = "la-am-eastus-prod-myelx"; $LogAnalyticsResourceGroup ="rg-am-eastus-myelx-mgmt"; Break}                
    "CUST-A-EU-NONPROD-V2" {$LogAnalyticsWorkspace = "la-eu-uksouth-nonprod-v2"; $LogAnalyticsResourceGroup ="RG-EU-UKSouth-NonProd-V2-MGMT"; Break}        
    "CUST-A-EU-NONPROD" {$LogAnalyticsWorkspace = "la-eu-weurope-NonProd"; $LogAnalyticsResourceGroup ="RG-EU-UKSouth-NonProd-Mgmt"; Break}           
    "CUST-A-AP-NONPROD" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod"; $LogAnalyticsResourceGroup ="rg-ap-southeastasia-nonprod-mgmt"; Break}            
    "CUST-A-AM-POC" {$LogAnalyticsWorkspace = "la-am-eastus-POC"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-POC-Mgmt"; Break}               
    "CUST-A-AM-NONPROD-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-DataLake"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-DataLake-Mgmt"; Break}  
    "CUST-A-AM-NONPROD" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-Mgmt"; Break}
    "CUST-A-AM-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-CEPLATAM"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-NonProd-CEPLATAM-Mgmt"; Break}          
    "Bobbi Brown" {$LogAnalyticsWorkspace = "la-am-eastus-bobbibrown-mgmt"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-BobbiBrown-Mgmt"; Break}              
    "MyELC" {$LogAnalyticsWorkspace = "la-AM-EastUS-MyELC"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-MyELC-MGMT"; Break}                    
    "CUST-A-AM-PUBLIC" {$LogAnalyticsWorkspace = "la-am-eastus-Public"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Public-Mgmt"; Break}             
    "CUST-A-NONPROD-SAP" {$LogAnalyticsWorkspace = "la-nonprod-sap"; $LogAnalyticsResourceGroup ="rg-nonprod-sap-mgmt"; Break}           
    "CUST-A-PROD-SAP" {$LogAnalyticsWorkspace = "la-prod-sap"; $LogAnalyticsResourceGroup ="rg-prod-sap-mgmt"; Break}             
    "CUST-A-AM-PROD-CORNERSTONE" {$LogAnalyticsWorkspace = "la-prod-cornerstone"; $LogAnalyticsResourceGroup ="rg-prod-cornerstone-mgmt"; Break}   
    "CUST-A-AM-PROD-O9" {$LogAnalyticsWorkspace = "la-am-eastus-prod-o9"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-o9-mgmt"; Break}            
    "CUST-A-AM-PROD-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-Prod-CEPLATAM"; $LogAnalyticsResourceGroup ="RG-AM-EastUS-Prod-CEPLATAM-Mgmt"; Break}      
    "CUST-A-AM-PROD-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-prod-edlna"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-edlna-mgmt"; Break}     
    "CUST-A-AM-NONPROD-CORNERSTONE" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-cornerstone"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-cornerstone-mgmt"; Break}
    "CUST-A-AM-NONPROD-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-e2e"; $LogAnalyticsResourceGroup ="rg-am-eastus-nonprod-e2e-mgmt"; Break}  
    "CUST-A-AM-PROD-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-prod-e2e"; $LogAnalyticsResourceGroup ="rg-am-eastus-prod-e2e-mgmt"; Break}
    "CUST-A-CN-PROD" {$LogAnalyticsWorkspace = "la-cn-chinaeast2-prod"; $LogAnalyticsResourceGroup ="RG-CN-ChinaEast2-Prod-Mgmt"; Break}  
    #"CUST-A-AM-POC-V2" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}            
    #"GCCS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                      
    #"CUST-A-AP-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}              
    #"CUST-A-EU-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                        
    #"CUST-A APAC PoC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}             
    #"CUST-A APAC Public" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}          
    #"CUST-A App Dev Migration" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
    #"CUST-A-AM-DR-C2M" {$LogAnalyticsWorkspace = "LogAnalytics-AM-EastUS-DR-C2M"; $LogAnalyticsResourceGroup ="rg-am-eastus-dr-c2m-azuremgmt"; Break}            
    #"CUST-A-AM-Security-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}      
    #"CUST-A-AP-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"CUST-A-EU-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"CUST-A-Windows-Analytics" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}    
    #"HCLTools" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}  
    #"SAP" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                       
    #"CUST-A-GLOBAL-OPERATIONS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
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

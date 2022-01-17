**PARAMETERS**
Alphabetical list of all parameters found within the ECS Azure Demo templates

| Parameter| Definition | Example Values |
|----------------|-------------------------------------------------------|------------------|
| adminDbEdition | Azure SQL Database Sku for the admin database | Basic|
| adminDbName | Azure SQL database Name for the admin database | BirstAdmin |
| adminDbPlan | Azure SQL database pricing tier for the admin database | basic |
| application | The name of the deployed application | Core, Monaco, Mosaiq |
| autoShutdownTime | Time to auto-shutdown a virtual machine | 19:00 |
| autoShutdownTimezone | Timezone for auto-shutdown | 'Central Standard Time' |
| autoShutdownTimeStatus | Enable or disable the auto shutdown | Disabled |
| billingIdentifier | Dictate a charge cost or cost center for billing resources against | 0000000 |
| customer | Dictate the functional department owner of the resource(s) to facilitate chargebacks and forecasting | XYZ |
| containerSasToken |  SAS token required to access Azure Blob Storage Containe | |
| containerUri | Uri of Azure Blob Storage Container with the linked ARM templates | https://elektavsts.blob.core.windows.net/devtemplates |
| corporateEndIPAddress | Corporate IP End for firewall | 0.0.0.0 |
| corporateStartIPAddress |  Corporate IP Start for firewall | 0.0.0.0 |
| dataDbEdition | Azure SQL Database Sku for the data database | Standard |
| dataDbName | Azure SQL database Name for the data database | BirstData |
| dataDbPlan | Azure SQL database pricing tier for the data database | S1 |
| dbCollation | The collation for the Azure SQL database | SQL_Latin1_General_CP1_CI_AS |
| dbMaxSizeBytes | Max size of the Azure SQL database in bytes | 1073741824 |
| decomDate |Provides a date when the environment or resource group is to be decommissioned or removed from Azure. |2017-04-17 |
| deployDate | Provides a date when the environment or resource group was provisioned into Azure. YYYY-MM-DD | 2017-04-15 |
| diagnosticsStorageAccountName | Name of the diagnostics storage account | dglobaleastuscoresalogs |
| diagnosticsStorageAccountRG | Resource group of the diagnostics storage account | DEV-GLOBAL-EASTUS-CORE-RG |
| environment | The environment that is being deployed | Prod, Dev, Test |
| environmentTier | Tier of the environment being deployed | Global, Regional, Customer |
| fullDbName | Concatenation of db server and db name | dev-regional-eastus-birst1/DEV-REGIONAL-EASTUS-BIRSTADMIN-DB |
| gatewaySku | The Sku of the VPN Gateway | Basic, Standard or HighPerformance. |
| globalGatewayName | Name of the global gateway that is being connected to a regional subscription | DEVGLOBALSOUTHCENTRALUSVNETGW |
| globalGWResourceGroupName | Name of the resource group of the globalgateway | DEMOGLOBALEASTUSVNETGW |
| globalSubscriptionID | SubscriptionID of the globalsubscription | 0d7a2cad-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| installVSTSAgent | Installs the VSTS Deployment Agent | "yes" - install |
| movexID | customer number | 12345 |
| privateIPAddress |  internal static IP of a server (if required) | 10.0.1.4 |
| regionalGatewayName | Name of the regional gateway that is being connected to the Global subscription |  DEVREGIIONALSOUTHCENTRALUSVNETGW |
| regionalGWResourceGroupName | Name of the resource group of the regional gateway | DEMOREGIONALEASTUSVNETGW |
| regionalSubscriptionID | SubscriptionID of the regional subscription | 0d7a2cad-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| schedulerDbEdition | Azure SQL Database Sku for the scheduler database | Basic |
| schedulerDbName | Azure SQL database Name for the scheduler database | BirstScheduler |
| schedulerDbPlan | Azure SQL database pricing tier for the scheduler database | Basic |
| serviceContract | Service Contract Number | 987654321 |
| sharedKey | Shared Key (PSK) applied to two connection virtual networks for the VPN IPSec Tunnel | sharedkeyvalue | 
| sqlAdministratorLogin | The admin user of the SQL Server | sqladmin |
| sqlAdministratorLoginPassword | The password of the admin user of the SQL Server | password |
| sqlServerName | Azure SQL Server Name | dev-regional-eastus-birst1 |
| storageAccountName | Azure Storage account name | ddregionaleastuscoresa |
| storageAccountType | Azure Storage account type | Standard_LRS |
| subnetOctet | The first two octets for the subnet(s) | 10.10. |
| virtualNetworkName | Name of the virtual network the resource is being deployed to | DEV-GLOBAL-EASTUS-CORE-VNET |
| vmAdminUserName | Local Administrator Username | localadmin |
| vmAdminPassword | Local Administrator Password | password |
| vmImageOffer | Type of virtual machine server image being offered | WindowsServer |
| vmImagePublisher | Publisher of the virtual machine image | MicrosoftWindowsServer |
| vmImageSku | Version of the virtual machine image offer | 2016-datacenter |
| vmName | Suffix related to a virtual machines purpose |  BIR :: DEUS**BIR**01 | 
| vmSize | Azure specific virtual machine size | Standard_D2_v2 |
| vnetAddressPrefix | The address prefix of the Virtual Network being deployed or referenced | 10.10.0.0/16 |
| vNetRG | Name of the virtual network resource group | DEV-GLOBAL-EASTUS-CORE-RG |
| vpnType | Route based (Dynamic Gateway) or Policy based (Static Gateway) | RouteBased or PolicyBased |
| vstsAccount | Name of the VSTS account to join the Deployment Agent to | elektacloud |
| vstsAgentTags | Comma-separated list of tags to apply to the agent | DOMAINCONTROLLER,GLOBAL |
| vstsAgentType | Type of agent to install (Windows or Linux) | TeamServicesAgent |
| vstsDeploymentGroup | Name of the VSTS Deployment Group to join the agent to | Global |
| vstsPat | PAT (Personal Access Token) to join the Deployment Group |  |
| vstsTeamProject | Name of the VSTS team project that contains the Deployment Group | 'ECS Azure Demo v2' |
| licenseType | Specifies the license type of the VM | 'Windows_Server' |
| vmNicName | the prefix used for the name of the NIC the vm will use | 'PROD-REGIONAL-WESTEUROPE-PWEUCXC' |
| omsAgentType | Specifies the platform for the agent | 'MicrosoftMonitoringAgent' |
| installOMSAgent | Decide to install the oms agent or not | 'yes' |
| omsWorkspaceID | The oms workspace ID the vm will register with | '235e16d3-2b95-449e-9b40-9ed47e41e9c8' |
| omsWorkspaceKey| The oms workspace key the vm will use to authenticate to register with OMS | 'it is a secret' |
| dscRegistrationUrl | The URL of the azure automation account the vm will register with | 'https://eus2-agentservice-prod-1.azure-automation.net/accounts/fe06d6bd-6b0f-409a-86bb-3a37bb87766d'|
| dscExtensionUpdateTagVersion | Sets the DSC extension to forced an update for every new release, the 2 in the example is the release number which will change if you run a new release  | 'DSC_UK-REGIONAL-2' the 2 here is the release number which will change if you run a new release|
| dscNodeConfigName | The node configuration the vm will execute when it registers with the automation account| 'RegionalXenDesktopController.XenDesktopRegional-PRDOWEU'|
| dscNodeConfigNameStringFormat | The node configuration for a vm that requires high availability | 'GlobalDomainController.PRIMARYGDC-PROD-CAC'|
| dscConfigMode | Determines the configuration mode for DSC | 'ApplyOnly'|
| dscRefreshFrequencyMins | Specifies how often the configuration engine (LCM) attempts to check with the automation account for updates | 30|
| dscConfigurationModeFrequencyMins | Specifies how often LCM validates the current configuration | 15|
| count | Used as counter when deploying more than one resource| 2 |
| tagExtension | This allows you to add more tags to the base tags specified in the main vm template | 'Server function:"Tableau Server"|
| installAntiVirus | Decides whether to install the AV software or not | 'yes'|
| pathExclusionPath | Files paths to exclude during the AV scan ||
| fileExtensionExclusion| Files extensions to exclude during the AV scan ||
| processExclusion| processes to exclude during the AV scan ||
| realtimeProtectionEnabled| Decides whether to enable or disable ||






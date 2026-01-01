// Action Groups Module
// Configures notification routing for alerts
// Supports email, webhook (ITSM), and automation runbooks

@description('Name for the action group')
param actionGroupName string

@description('Email addresses for notifications')
param emailAddresses array = []

@description('Webhook URL for ITSM integration')
param itsmWebhookUrl string = ''

@description('Resource tags')
param tags object = {}

// Short name is limited to 12 characters
var shortName = take(replace(actionGroupName, '-', ''), 12)

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: shortName
    enabled: true
    
    // Email receivers
    emailReceivers: [for (email, i) in emailAddresses: {
      name: 'email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    
    // ITSM webhook integration
    // This is where you connect to ServiceNow, Jira, PagerDuty, etc.
    // The webhook receives the Common Alert Schema payload
    webhookReceivers: !empty(itsmWebhookUrl) ? [
      {
        name: 'itsm-integration'
        serviceUri: itsmWebhookUrl
        useCommonAlertSchema: true
        useAadAuth: false // Set to true if your ITSM requires AAD auth
      }
    ] : []
  }
}

// Separate action group for critical alerts
// Consider different routing for Sev0/Sev1 vs informational alerts
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${actionGroupName}-critical'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: take('${shortName}crit', 12)
    enabled: true
    
    emailReceivers: [for (email, i) in emailAddresses: {
      name: 'critical-email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    
    // For critical alerts, you might want SMS or voice call
    // Uncomment and configure as needed:
    // smsReceivers: [
    //   {
    //     name: 'oncall-sms'
    //     countryCode: '1'
    //     phoneNumber: 'YOUR_PHONE_NUMBER'
    //   }
    // ]
    
    webhookReceivers: !empty(itsmWebhookUrl) ? [
      {
        name: 'itsm-critical'
        serviceUri: itsmWebhookUrl
        useCommonAlertSchema: true
        useAadAuth: false
      }
    ] : []
  }
}

// Outputs
output actionGroupId string = actionGroup.id
output criticalActionGroupId string = criticalActionGroup.id
output actionGroupName string = actionGroup.name
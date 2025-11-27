# Dashboard Manager

Introduction to Dashboard Manager

[[_TOC_]]

## **Input Form**

## **Dashboard Form Input Logic App**

## **Dashboard Libary Cosmos Db**

When choosing a database to store the information required of the dashboard library SQL was discussed.  However, it was determined the complexties to store and model the database were very high and a relational database was not a good fit for the goal of the dashboard.  Then it was decided to go with 
The Dashboard Library is seperated into three containers in the Cosmos Db **MSP-dashboard-library-db**.

* DashboardType
* parts
* templates

### DashboardType Container

#### Key - /type

#### JSON File Format

```JSON
{
    "type": "{Micosoft-Resource-Type}",
    "priority": "{priority-number-order-on-dashboard}",
    "height": "{height-of-type-on-dashboard}",
    "parts": "'Name of each part', 'in the section', 'type'",
    ...
}
```

### parts Container

Parts

#### Key - /name

#### Part JSON File Format

```JSON
{
    "name": "{name-of-part}",
    "part": {
        "position": {
            "x": "{number-of-x-coordinate-in-type-section}",
            "y": "{number-of-y-coordinate-in-type-section}",
            "colSpan": "{number-of-colSpan-width-in-type-section}",
            "rowSpan": "{number-of-rowSpan-height-in-type-section}"
        },
        "metadata" : "{structure-of-the-part}"
    }
}

```

### templates Container

#### Key - /metadata/name

#### Template JSON File Format

```JSON
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "metadata": {
        "name" : "{name-of-starting-template}"
    },
    "contentVersion": "1.0.0.0",
    "parameters": { },
    "variables": {},
    "resources" :[]
}

```

## **Dashboard Deployment**

The Dashboard Deployment is executed by leveraging the logic app **MSP-dashboard-deployment**.  This logic app receives an http request from **MSP-dashboard-form-input** process the input and then builds an ARM Template dynamically.  The template represents a dashboard for the application which is being monitored.

### **Integration Account**

One of the requirements to handle the complexity of this Logic App was to use Inline JavaScript steps.  The prerequist to running Inline JavaScript code in a Logic App is to have an _Integration Account_ associated with the Logic App. [Click here to learn more about Integration Accounts](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-create-integration-account).  The integration account associated with the **MSP-dashboard-deployment** is **MSP-dashaboard-integration-account** and is currently configured for the Free Pricing Tier.

### **Logic App**

#### **HTTP Request**

![alt text](./Documentation/HttpRequestResponse.jpg "HTTP Request Steps")

#### **Initialize Variables**

![alt text](./Documentation/InitializeVariables.jpg "Initialize Variable Steps")

#### **Get & Process Base Template**

![alt text](./Documentation/ProcessBaseTemplate.jpg "Process Base Template Steps")

##### **Get Current Parts**

```javascript
var template = workflowContext.actions.Get_Template.outputs.body.Documents[0];

var parts = template.resources[0].properties.lenses[0].parts;

var output = {
    "index": Object.keys(parts).length,
    "parts": parts
}

return output;

```

#### **Sort & Process Types**

![alt text](./Documentation/ProcessTypes.jpg "Sort Process Types Steps")

#### **Sort Resource Types**

```javascript
function priority(current_type, next_type) {
    let comparison = 0;
    if (current_type.priority > next_type.priority) {
        comparison = 1;
    } else if (current_type.priority < next_type.priority) {
        comparison = -1;
    }
  
    return comparison;
}

var  types = workflowContext.actions.Get_Type.outputs.body.Documents
return types.sort(priority);
var results = [];

types.forEach(type => {
    results.push(type.parts);
});

return results;

```

### **Build ARM Template**

![alt text](./Documentation/BuildTemplate.jpg "Build Template Steps")

```javascript
var template = workflowContext.actions.Get_Template.outputs.body.Documents[0];

template.resources[0].properties.lenses[0].parts = workflowContext.actions.All_Parts.outputs

delete template["id"];
delete template["_rid"];
delete template["_self"];
delete template["_etag"];
delete template["_attachments"];
delete template["_ts"];

return template;
```

### **Deploy ARM Template**

## Deployment Order

{: .text-center}

1. connections
    1. api.connection.arm.json
    1. api.connection.cosmosdb.json
    1. integration.account.template.json
1. logicapp.MSP.dashboard.deployment.json
1. logicapp.MSP.dashboard.form.input.json

## **Authors**

Christopher Witcher
Jason Rinehart

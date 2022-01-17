# Linked Templates via Blob Containers
To minimize copying, we use _linked templates_. "Parent" templates can invoke resources that are defined in Linked Templates.

The process for deployment is as follows:
1. Upload the templates to a container in Blob storages
1. Generate a SAS token to access the files
1. Pass the container URL and SAS token in to the parent template
1. The parent template invokes a `Microsoft.Resources/deployments` resource to refer to the linked template

## Referring to Linked Templates in an ARM template

### Linked (child) template
Defined the resources as usual and ensure that you specify parameters accordingly. Here's an example for deploying a VNet using `copy` to create multiple subnets from an object parameter:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vnetName": {
      "type": "string"
    },
    "vnetPrefix": {
      "type": "string"
    },
    "subnets": {
      "type": "object"
    }
  },
  "variables": {
  },
  "resources": [
    {
      "name": "[parameters('vnetName')]",
      "type": "Microsoft.Network/virtualNetworks",
      "location": "[resourceGroup().location]",
      "apiVersion": "2016-03-30",
      "dependsOn": [],
      "tags": {
        "displayName": "vnet"
      },
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[parameters('vnetPrefix')]"
          ]
        }
      }
    },
    {
      "apiVersion": "2015-06-15",
      "type": "Microsoft.Network/virtualNetworks/subnets",
      "tags": {
        "displayName": "Subnets"
      },
      "copy": {
        "name": "iterator",
        "count": "[length(parameters('subnets').settings)]"
      },
      "name": "[concat(parameters('vnetName'), '/', parameters('subnets').settings[copyIndex()].name)]",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[parameters('vnetName')]"
      ],
      "properties": {
        "addressPrefix": "[parameters('subnets').settings[copyIndex()].prefix]"
      }
    }
  ],
  "outputs": {
  }
}
```

### Parent template
Add `containerUri` and `containerSasToken` parameters to your "parent" template. Then use those to construct the path to the linked template. For example: `"uri": "[concat(parameters('containerUri'), '/Resources/vNet.json', parameters('containerSasToken'))]"`.

Here's an example parent template:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "containerUri": {
      "type": "string"
    },
    "containerSasToken": {
      "type": "string"
    }
  },
  "variables": {},
  "resources": [
    {
      "apiVersion": "2017-05-10",
      "name": "linkedTemplate",
      "type": "Microsoft.Resources/deployments",
      "properties": {
        "mode": "incremental",
        "templateLink": {
          "uri": "[concat(parameters('containerUri'), '/Resources/vNet.json', parameters('containerSasToken'))]",
          "contentVersion": "1.0.0.0"
        },
        "parameters": {
          "vnetName": { "value": "testVNet" },
          "vnetPrefix": { "value": "10.0.0.0/16" },
          "subnets": {
            "value": {
              "settings": [
                {
                  "name": "subnet1",
                  "prefix": "10.0.0.0/24"
                },
                {
                  "name": "subnet2",
                  "prefix": "10.0.1.0/24"
                }
              ]
            }
          }
        }
      }
    }
  ],
  "outputs": {}
}
```

### A note on Parameter Objects
When passing simple types to the linked parameter, you still need to specify the `value` property. So if the child parameter is
```json
    "vnetName": {
      "type": "string"
    }
```
then the way to pass a value in is:
```json
       "parameters": {
          "vnetName": { "value": "testVNet" },
```

If you're using a complex object, you should create it with at least one property - so don't make it an array, for example: make it have a property called `settings` that is an array.

For example, in the parent template you could have:
```json
          "subnets": {
            "value": {
              "settings": [
                {
                  "name": "subnet1",
                  "prefix": "10.0.0.0/24"
                },
                {
                  "name": "subnet2",
                  "prefix": "10.0.1.0/24"
                }
              ]
            }
          }
```

In the linked template, you'd dereference `subnets.settings[index].name` to get the name of a subnet.

## VSTS Release Management
Fortunately VSTS makes the deployment really easy once you have the linked templates defined.

1. Create a new Release Definition
1. Add the repo containing templates as an artifact
1. Add an `Azure File Copy` task and set the parameters similar to this:
   ![image.png](.attachments/image-df6cba45-24fe-4c85-8f3f-084b6bec6e72.png)
1. Add an `Azure Resource Group Deployment` task and use the `containerUri` and `containerSasToken` variables:
   ![image.png](.attachments/image-66818e1c-b134-4efa-8dd1-10ccee64c079.png)

# Azure RBAC
This repository contains ARM templates to apply RBAC roles to a Resource Group.  It contains two separate templates. One for a single user or group and one for multiples.

## Single Role Assignment Template Notes [rbac.json]

This template assigns Owner, Reader or Contributor access to an existing resource group. Inputs to this template are following fields:

- Principal ID
- Role Definition Type

Other roles can be added as necessary to the allowed values in the builtInRoleType parameter.

The guid function uses both the Resource Group ID and the Deployment Name to generate a unique GUID.  Therefore, if you rerun the template you'll need to change the deployment name or else you'll get an error like this:
```
Deployment failed. Correlation ID: 00000000-0000-0000-0000-000000000000. {
  "error": {
    "code": "RoleAssignmentUpdateNotPermitted",
    "message": "Tenant ID, application ID, principal ID, and scope are not allowed to be updated."
  }
}
```

**Use following PowerShell command to get Principal ID associated with a user using their email id. Please note, principal id maps to the id inside the directory and can point to a user, service principal, or security group. The ObjectId is the principal ID.

    PS C:\> Get-AzureRmADUser -mail <email id>

    DisplayName                    Type                           ObjectId
    -----------                    ----                           --------
    <NAME>                                                        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx


## Multirole RoleAssignment Template Notes [rbac-multiuser.json]

This template is a little more advanced and uses an array as input and a copy loop to apply multiple users/groups  role assignments to the Resource Group.  The principals are exactly the same as the single user/group deployment template.

The parameters are of the form:
```
    {
      "name": "Jennifer Morris",
      "principalId": "00000000-0000-0000-0000-000000000000",
      "roleDefinitionId": "Reader"
    },
```

The "name" field is not required for the ARM Rest API call but was added to help delineate the possible numerous entries with a name for clarity's sake.

## Examples

### Azure CLI Single User/Group Deployment

```
az group deployment create --name "rbac1" --resource-group rg-region1-POC-MSP-CEP-RBAC --template-file "./rbac.json" --parameters "./rbac.parameters.json"
```

### Azure CLI Single User/Group Deployment

```
az group deployment create --name "rbac1" --resource-group rg-region1-POC-MSP-CEP-RBAC --template-file "./rbac-multiuser.json" --parameters "./rbac.parameters-mulituser.json"
```

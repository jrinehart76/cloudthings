## Purpose

Creates a base Logic App with no trigger, output, or actions defined.  Generally these items are handled by the developer during development.  These can be inserted into the template at that time.  Passing these items as parameters is not done b/c ARM templating language is not verbose enough to allow complex workflows to be passed via replacement parameters.  


## Prerequisites for Logic App with Service Principal

1. `Create AAD application` for the Logic App.  
2. The AAD application ID is needed for the Logic app definition and is passed in a parameter.  

* in AAD click **Applications**
* **Add** 
* Name the identity 
* create the unique domain string
* **Configure** tab for the application
* for the Keys select 1 or 2 years
* **Save**
* Copy the key.  This is used as the parameter for `logicAppClientSecret`

## Assumptions


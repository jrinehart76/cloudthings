function Merge-HashTables {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [alias('OldTags')]
        [AllowNull()]
        [hashtable]
        $OriginalHashTable,
        
        [Parameter(Mandatory = $true)]
        [alias('NewTags')]
        [hashtable]
        $NewHashTable
    )

    if (!$OriginalHashTable) {
        Write-Verbose "OriginalHashTable is empty, returning only NewHashTable"
        return $NewHashTable
    }

    else {
        $OriginalHashTableClone = $OriginalHashTable.Clone()
        
        foreach ($key in $NewHashTable.Keys) {
            if ($OriginalHashTableClone.ContainsKey($key)) {
                Write-Verbose "`tRemoving existing tag `"$($key)`""
                $OriginalHashTableClone.Remove($key)
            }
        }

        return $OriginalHashTableClone + $NewHashTable
    }
}

function Convert-ObjectToHashTable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $InputObject
    )
    
    Write-Verbose "Converting PSCustomObject to hash table"
    $hash = @{}
    foreach ($key in ($InputObject | Get-Member -MemberType NoteProperty).Name) {
        Write-Verbose "`t$($key): $($InputObject.$key)"
        $hash[$key] = $InputObject.$key
    }
    return $hash
}

function Import-RequiredModules {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string[]]
        $RequiredModules = @(
            "AzureRM"
        )
    )
    try {
        Write-Output "`nLoading required modules"
        Write-Verbose "Checking all loaded modules"
        $loadedModules = Get-Module
        foreach ($module in $RequiredModules) {
            Write-Output "$($module)"
            Write-Verbose "Checking if module is loaded"
            if ($loadedModules.Name -notcontains $module) {
                Write-Verbose "Module not loaded, attempting to load"
                Import-Module $module -ErrorAction Stop -Verbose:$false
            }
            else {
                Write-Verbose "Module already loaded"
            }
        }
    }
    catch {
        Throw "$($_.Exception.Message)"
    }
}


function Set-AzureAuthentication {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param(
        [Parameter(Mandatory = $false, ParameterSetName = "UseContextFile")]
        [switch]
        $ImportContext,

        [Parameter(Mandatory = $true, ParameterSetName = "UseContextFile")]
        [string]
        $PathToContextFile,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    
    try {
        Write-Verbose "Testing authentication to Azure"
        if ($Force) {
            Write-Verbose "Force switch used, skipping authentication context check"
            $authenticate = $true
        }
        else {
            Write-Verbose "Checking for current authentication context"
            $context = Get-AzureRmContext
            if ([string]::IsNullOrEmpty($context.Account)) {
                Write-Verbose "No authentication context found"
                $authenticate = $true
            }
            else {
                Write-Verbose "Context found"
                Write-Verbose "Id: $($context.Account.Id)"
                Write-Verbose "Tenant: $($context.Tenant.Id)"
                $authenticate = $false
            }
        }

        if ($authenticate) {
            Write-Output "`nAuthenticating to Azure"
            if ($ImportContext) {
                Write-Verbose "Importing context from $($PathToContextFile)"
                Import-AzureRmContext -Path $PathToContextFile -ErrorAction Stop | Out-Null
            }
            else {
                Write-Verbose "Prompting for credentials"
                Connect-AzureRmAccount -ErrorAction Stop | Out-Null
            }
        }
        Write-Output "`n"
    }

    catch {
        Throw "$($_.Exception.Message)"
    }
    
}

function Set-AzureSubscriptionContext {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [alias('SubscriptionId', 'SubscriptionName')]
        [string]
        $Subscription,

        [Parameter(Mandatory = $false, ParameterSetName = "UseContextFile")]
        [switch]
        $ImportContext,

        [Parameter(Mandatory = $true, ParameterSetName = "UseContextFile")]
        [string]
        $PathToContextFile,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )
    
    try {
        Import-RequiredModules
        Write-Output "`nUsing subscription: $($Subscription)"

        if ($Force) {
            Write-Verbose "Force switch used, skipping subscription context check"
            $authenticate = $true
        }
        
        else {
            Write-Verbose "Checking current subscription context"
            $context = Get-AzureRmContext
            if ($context.Subscription.Id -ne $Subscription -and $context.Subscription.Name -ne $Subscription) {
                Write-Verbose "Context not set to subscription"
                $authenticate = $true
            }
            else {
                Write-Verbose "Subscription context already set to: $($Subscription)"
                $authenticate = $false
            }
        }
        if ($authenticate) {
            Write-Verbose "Calling set authentication function`n"
            $PSBoundParameters.Remove('Subscription') | Out-Null
            Set-AzureAuthentication -ErrorAction Stop @PSBoundParameters
                
            Write-Output "Setting subscription context to: $($Subscription)"
            Set-AzureRmContext -Subscription $Subscription -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Throw "$($_.Exception.Message)"
    }
}

function Write-AzureResourceGroup {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]
        $Location,

        [Parameter(Mandatory = $false, ParameterSetName = "ApplyTags")]
        [switch]
        $IncludeParameterTags,

        [Parameter(Mandatory = $true, ParameterSetName = "ApplyTags")]
        [string]
        $ParameterFilePath
        
    )
    try {
        Write-Output "`nUsing resource group: $ResourceGroupName"
        
        Write-Verbose "Checking for existing resource group"
        $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if ($resourceGroup) {
            Write-Verbose "Existing resource group found"
        }
        else {
            Write-Verbose "Existing resource group not found"
            Write-Output "Creating resource group $($ResourceGroupName) in location $($Location)"
            $resourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
        }

        if ($IncludeParameterTags) {
            Write-Output "Applying tags to resource group"
            Write-Verbose "Loading tags from parameter file: $($ParameterFilePath)"
            $parameterTags = (Get-Content -Path $ParameterFilePath -Raw | ConvertFrom-Json).parameters.tags.value
            Write-Verbose "Converting tags to hash table"
            $newTags = Convert-ObjectToHashTable -InputObject $parameterTags
            Write-AzureTags -ResourceGroup $resourceGroup -NewTags $newTags
        }
        Write-Output "`n"
    }
    catch {
        Write-Error "$($_.Exception.Message)"
    }
}

function Write-AzureResourceGroupTagsFromJSON {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $InputFile,

        [Parameter(Mandatory = $false)]
        [Switch]
        $UpdateChildResrouces,

        [Parameter(Mandatory = $false)]
        [switch]
        $PurgeOldTags
    )
    try {
        Write-Output "`nAdding tags from JSON file"

        $params = @{}
        if ($PurgeOldTags) {
            $params.Add('PurgeOldTags', $true)
        }

        Write-Verbose "Loading JSON file and converting from text to JSON"
        $json = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
        Write-Verbose "Converting tags to hash table"
        $newTags = Convert-ObjectToHashTable -InputObject $json.tags

        #Process Resource Groups
        foreach ($resourceGroupName in $json.resourceGroups) {
            Write-Output "`nProcessing resource group: $($resourceGroupName)"
            Write-Verbose "Loading resource group"
            $resourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $resourceGroupName -ErrorAction Stop
            Write-AzureTags -ResourceGroup $resourceGroup -NewTags $newTags @params

            if ($UpdateChildResrouces) {
                #Process Resources in RG
                Write-Verbose "Processing child resources"
                Write-Verbose "Loading resources in resource group"
                foreach ($resource in (Get-AzureRmResource -ResourceGroupName $resourceGroupName)) {
                    Write-Output "Processing child resource: $($resource.Name)"
                    Write-AzureTags -Resource $resource -NewTags $newTags @params
                }
            }
            else {
                Write-Verbose "Skipping child resources"
            }
        }
    }
    catch {
        Write-Error "$($_.Exception.Message)"
    }
}

function Copy-AzureTagsFromResourceGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [switch]
        $PurgeOldTags
    )
    try {
        $params = @{}
        if ($PurgeOldTags) {
            $params.Add('PurgeOldTags', $true)
        }

        Write-Output "`nProcessing resource group: $($ResourceGroupName)"
        Write-Verbose "Loading resource group"
        $resourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        $newTags = $resourceGroup.Tags

        #Process Resources in RG
        Write-Verbose "Processing child resources"
        Write-Verbose "Loading resources in resource group"
        foreach ($resource in (Get-AzureRmResource -ResourceGroupName $ResourceGroupName)) {
            Write-Output "Processing child resource: $($resource.Name)"
            Write-AzureTags -Resource $resource -NewTags $newTags @params
        }
    }
    catch {
        Write-Error "$($_.Exception.Message)"
    }
}

function Write-AzureTags {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = "ResourceGroup")]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]
        $ResourceGroup,

        [Parameter(Mandatory = $true, ParameterSetName = "Resource")]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource]
        $Resource,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $NewTags,

        [Parameter(Mandatory = $false)]
        [switch]
        $PurgeOldTags
    )
    try {

        Write-Verbose "Processing tags"
        if ($PurgeOldTags) {
            Write-Verbose "PurgeOldTags called, discarding existing resource tags"
            $tagsToAdd = $NewTags
        }
        else {
            switch ($PSCmdlet.ParameterSetName) {
                "ResourceGroup" {
                    Write-Verbose "Merging new tags with existing resource group tags"
                    $oldTags = $ResourceGroup.Tags
                }
                "Resource" {
                    Write-Verbose "Merging new tags with existing resource tags"
                    $oldTags = $Resource.Tags
                }
            }
            $tagsToAdd = Merge-HashTables -OldTags $oldTags -NewTags $newTags
        }

        switch ($PSCmdlet.ParameterSetName) {
            "ResourceGroup" {
                Write-Verbose "Writing tags to resource group"
                $ResourceGroup | Set-AzureRmResourceGroup -Tag $tagsToAdd -ErrorAction Stop | Out-Null
            }
            "Resource" {
                Write-Verbose "Writing tags to resource"
                Set-AzureRmResource -ResourceId $Resource.Id -Tag $tagsToAdd -ErrorAction Stop -Force | Out-Null
            }
        }
    }
    catch {
        Write-Error "$($_.Exception.Message)"
    }
}

function New-AzureTemplateDeployment {
    [CmdletBinding(DefaultParameterSetName = 'None')]

    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]
        $Location,

        [Parameter(Mandatory = $false)]
        [string]
        $DeploymentPrefix = "Microsoft.Template",

        [Parameter(Mandatory = $true)]
        [string]
        $TemplateFilePath,

        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $true, ParameterSetName = "ApplyTags")]
        [string]
        $ParameterFilePath,

        [Parameter(Mandatory = $false, ParameterSetName = "ApplyTags")]
        [switch]
        $IncludeParameterTags
        
    )
    
    try {
        Import-RequiredModules
        $deploymentName = "$($DeploymentPrefix)_$(Get-Date -Format yyyyMMdd_HHmm)"
        Write-Output "`nStarting deployment $($deploymentName)"

        Write-Verbose "Setting resource group"
        $rgParams = @{
            'ResourceGroupName' = $ResourceGroupName;
            'Location'          = $Location;
        }
        if ($IncludeParameterTags) {
            $rgParams.Add('IncludeParameterTags', $IncludeParameterTags)
            $rgParams.Add('ParameterFilePath', $ParameterFilePath)
        }
        Write-AzureResourceGroup -ErrorAction Stop @rgParams

        Write-Output "Deploying template"
        $deployParams = @{
            'ResourceGroupName' = $ResourceGroupName
            'Mode'              = 'Incremental'
            'Name'              = $deploymentName
            'TemplateFile'      = $TemplateFilePath
        }
        if ($ParameterFilePath) {
            $deployParams.Add('TemplateParameterFile', $ParameterFilePath)
        }
        New-AzureRmResourceGroupDeployment @deployParams
    }
    catch {
        Write-Error "$($_.Exception.Message)"
    }
}


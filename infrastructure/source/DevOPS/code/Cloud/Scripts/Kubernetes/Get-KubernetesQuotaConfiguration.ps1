param (
    [string[]]
    [parameter(Mandatory=$true)]
    $Namespace,
    [string[]]
    [parameter(Mandatory=$true)]
    $AKSQuotaCPUConfig,
    [string[]]
    [parameter(Mandatory=$true)]
    $AKSQuotaMemoryConfig,
    [string[]]
    [parameter(Mandatory=$true)]
    $AKSKubeConfigPath,
	[string[]]
    [parameter(Mandatory=$true)]
    $AdminADGroup

)


for ($i=0; $i -lt $Namespace.Count; $i++)
{
    try
        {
            Write-Verbose "Adding Namespace $($Namespace[$i])"
            kubectl create namespace $Namespace[$i] --kubeconfig $AKSKubeConfigPath
            Write-Verbose "Added Namespace $($Namespace[$i])"
			Write-Verbose "Setting VSTS Variable $($Namespace[$i])"

@"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $($Namespace[$i])-admins
  namespace: $($Namespace[$i])
subjects:
- kind: Group
  name: $($AdminADGroup)
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role 
  name: dev-user-full-access
  apiGroup: rbac.authorization.k8s.io
"@ | out-file d:\a\r1\a\_10thMagnitudeDevOps\code\CustomerA-Cloud\Scripts\Kubernetes\$($Namespace[$i]).yaml -enc ASCII

kubectl apply -f d:\a\r1\a\_10thMagnitudeDevOps\code\CustomerA-Cloud\Scripts\Kubernetes\$($Namespace[$i]).yaml --kubeconfig $AKSKubeConfigPath

        }
    catch
        {
            Write-Verbose $_
        }
}


for ($i=0; $i -lt $Namespace.Count; $i++)
{

    try
        {

            Write-Verbose "Adding Namespace Configuration for $($Namespace[$i])"
            kubectl create quota "$($Namespace[$i])" --hard=cpu="$($AKSQuotaCPUConfig[$i])",memory="$($AKSQuotaMemoryConfig[$i])" --namespace="$($Namespace[$i])" --kubeconfig $AKSKubeConfigPath
            Write-Verbose "Added Namespace Configuration for $($Namespace[$i])"
        }
    catch
        {
            Write-Verbose $_
        }
}

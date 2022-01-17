# You can write your azure powershell scripts inline here. 
# You can also pass predefined and custom variables to this script using arguments
Param(
    [parameter(Mandatory=$true)][string]$SkuFamily,
    [parameter(Mandatory=$true)][string]$SkuCapacity,
    [parameter(Mandatory=$true)][string]$SkuTier
)

if ($skuTier -match "Basic") {
$tiershort = "GP" }
else {   
$tiershort = $skuTier -creplace '[^A-Z]'
$SkuName = "$tiershort"+"_"+"$skufamily"+"_"+"$SkuCapacity"
}



Write-Output "##vso[task.setvariable variable=SkuName]$($SkuName)"
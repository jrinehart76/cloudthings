$subName = "CUST-A-AM-POC-DevOps"
$newRG = "False"
$ResourceGroupName = "test-netapp-arm"
$ResourceGroupLocation = "EastUS2"
$templateFile = "D:\repos\customer-a\cloudops\10thMagnitudeDevOps\code\CustomerA-Cloud\Templates\NetApp\NetApp.json"
$parameterFile = "D:\repos\customer-a\cloudops\10thMagnitudeDevOps\code\CustomerA-Cloud\Templates\NetApp\NetApp.parameters.json"
$verboseOutput = $true

if($newRG -eq "True"){
New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force
}else{}

Select-AzSubscription -SubscriptionName $subName -Verbose:$verboseOutput


New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $parameterFile `
    -Verbose:$verboseOutput


$subs = Get-AzSubscription
$urlList = @()
$gwList = @()
$filePath = "%USERPROFILE%\Documents"

foreach ($sub in $subs) {
    Set-AzContext -Subscription $sub.Name -InformationAction SilentlyContinue

    $gwResources = Get-AzResource -ResourceType 'Microsoft.Network/applicationGateways'

    foreach ($gwRes in $gwResources) {
        $gwName = Get-AzApplicationGateway -Name $gwRes.Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
        $gwList += $gwName
    }

    foreach ($gw in $gwList) {
        $listeners = Get-AzApplicationGatewayHttpListener -ApplicationGateway $gw -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
        $urlList += $listeners.Name
    }
}

$urlList | Out-File -Path $filePath
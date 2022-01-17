#Function to create Spoke networking, it requires the Range, the region, the Business unit ID, the type of environment.



function Create-Networking-For-Range { Param ($Range, $Region, $SubName, $Environment)
#Switch to identify the index for the resource group creation based on the location specified, default is to catch unavailable regions in case of error
switch ($Region) {
            eastus2{    $index = 1 
                        $dnsserver1 = "172.20.0.20"
                        $dnsserver2 = "172.20.0.22"
            }
            centralus{ $index = 2
                        $dnsserver1 = "172.21.0.20"
                        $dnsserver2 = "172.21.0.22"
            }
            northeu{ $index = 3
            }
            westeu{ $index = 4
            }
            eastasia{ $index = 5
            }
            southeastasia{ $index = 6
            }
            default{$index = 7}
        }
#Standardize the index into a 3 digits variable
$script:NumI = "{0:D3}" -f $index

#Create the resource group name
$RGName = $SubName+"-SNET-"+$NumI + "-$Environment"

#Create a partial name for the subnet names to use
$VnetName = $SubName+"SNET0"

#Decompose the range into several variables to use across the definitions of Subnets and Virtual network
$1oct,$2oct,$3oct, $rest = $range.split('.')
$4oct,$mask = $rest.split('/')

#Generate a variable with the first two octets for generating standarized names for the subnets
$12oct = $1oct + "." + $2oct + "."

#Creates Resource group with the information provided
$Resgroup = New-AzureRmResourceGroup -Name $RGName -Location $Region 
if ($mask -eq "22"){
#Generate all the different subnets using the standar pieces of the names and the range details set as standard by the network team
$subNet1 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "01" + $environment + "-" + $12oct+$3oct+".0_27") -AddressPrefix	($12oct + $3oct + ".0/27")
$subNet2 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "02" + $environment + "-" + $12oct+$3oct+".32_27") -AddressPrefix	($12oct + $3oct + ".32/27")
$subNet3 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "03" + $environment + "-" + $12oct+$3oct+".64_27")-AddressPrefix ($12oct + $3oct + ".64/27")
$subNet4 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "04" + $environment + "-" + $12oct+$3oct+".96_27") -AddressPrefix ($12oct + $3oct + ".96/27")
$subNet5 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "05" + $environment + "-" + $12oct+$3oct+".128_27") -AddressPrefix ($12oct + $3oct + ".128/27")
$subNet6 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "06" + $environment + "-" + $12oct+$3oct+".160_27") -AddressPrefix ($12oct + $3oct + ".160/27")
$subNet7 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "07" + $environment + "-" + $12oct+$3oct+".192_27") -AddressPrefix ($12oct + $3oct + ".192/27")
$subNet8 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "08" + $environment + "-" + $12oct+$3oct+".224_27") -AddressPrefix ($12oct + $3oct + ".224/27")
$subNet9 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "09" + $environment + "-" + $12oct+([int]$3oct+1)+".0_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".0/27")
$subNet10 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "10" + $environment + "-" + $12oct+([int]$3oct+1)+".32_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".32/27")
$subNet11 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "11" + $environment + "-" + $12oct+([int]$3oct+1)+".64_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".64/27")
$subNet11 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "12" + $environment + "-" + $12oct+([int]$3oct+1)+".96_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".96/27")
$subNet12 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "13" + $environment + "-" + $12oct+([int]$3oct+1)+".128_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".128/27")
$subNet13 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "14" + $environment + "-" + $12oct+([int]$3oct+1)+".160_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".160/27")
$subNet14 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "14" + $environment + "-" + $12oct+([int]$3oct+1)+".192_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".192/27")
$subNet15 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "15" + $environment + "-" + $12oct+([int]$3oct+1)+".224_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".224/27")
$subNet16 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "16" + $environment + "-" + $12oct+([int]$3oct+2)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".0/26")
$subNet17 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "17" + $environment + "-" + $12oct+([int]$3oct+2)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".64/26")
$subNet18 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "18" + $environment + "-" + $12oct+([int]$3oct+2)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".128/26")
$subNet19 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "19" + $environment + "-" + $12oct+([int]$3oct+2)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".192/26")
$subNet20 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "21" + $environment + "-" + $12oct+([int]$3oct+3)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".0/26")
$subNet21 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "21" + $environment + "-" + $12oct+([int]$3oct+3)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".64/26")
$subNet22 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "22" + $environment + "-" + $12oct+([int]$3oct+3)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".128/26")
$subNet23 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "23" + $environment + "-" + $12oct+([int]$3oct+3)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".192/26")

#Generate a single variable with the information about all the subnet configurations
$Subnets = $subNet1,$subNet2,$subNet3,$subNet4,$subNet5,$subNet6,$subNet7,$subNet8,$subNet9,$subNet10,$subNet11,$subNet12,$subNet13,$subNet14,$subNet15,$subNet16,$subNet17,$subNet18,$subNet19,$subNet20,$subNet21,$subNet22,$subNet23

#Generate the Virtual Network name with the range and index information
$VnetFullName = $SubName+"SNETVN"+$NumI + "$Environment-"+($Range -replace '/','_')

#Create the virtual network with all the subnet information created above
New-AzureRmVirtualNetwork -ResourceGroupName $Resgroup.ResourceGroupName -Location $region   -Name $VnetFullName -AddressPrefix "$Range" -Subnet $Subnets -DnsServer $dnsserver1,$dnsserver2
}
else{ 
#Generate all the different subnets using the standar pieces of the names and the range details set as standard by the network team
$subNet1 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "01" + $environment + "-" + $12oct+$3oct+".0_27") -AddressPrefix	($12oct + $3oct + ".0/27")
$subNet2 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "02" + $environment + "-" + $12oct+$3oct+".32_27") -AddressPrefix	($12oct + $3oct + ".32/27")
$subNet3 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "03" + $environment + "-" + $12oct+$3oct+".64_27")-AddressPrefix ($12oct + $3oct + ".64/27")
$subNet4 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "04" + $environment + "-" + $12oct+$3oct+".96_27") -AddressPrefix ($12oct + $3oct + ".96/27")
$subNet5 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "05" + $environment + "-" + $12oct+$3oct+".128_27") -AddressPrefix ($12oct + $3oct + ".128/27")
$subNet6 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "06" + $environment + "-" + $12oct+$3oct+".160_27") -AddressPrefix ($12oct + $3oct + ".160/27")
$subNet7 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "07" + $environment + "-" + $12oct+$3oct+".192_27") -AddressPrefix ($12oct + $3oct + ".192/27")
$subNet8 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "08" + $environment + "-" + $12oct+$3oct+".224_27") -AddressPrefix ($12oct + $3oct + ".224/27")
$subNet9 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "09" + $environment + "-" + $12oct+([int]$3oct+1)+".0_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".0/27")
$subNet10 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "10" + $environment + "-" + $12oct+([int]$3oct+1)+".32_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".32/27")
$subNet11 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "11" + $environment + "-" + $12oct+([int]$3oct+1)+".64_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".64/27")
$subNet11 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "12" + $environment + "-" + $12oct+([int]$3oct+1)+".96_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".96/27")
$subNet12 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "13" + $environment + "-" + $12oct+([int]$3oct+1)+".128_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".128/27")
$subNet13 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "14" + $environment + "-" + $12oct+([int]$3oct+1)+".160_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".160/27")
$subNet14 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "14" + $environment + "-" + $12oct+([int]$3oct+1)+".192_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".192/27")
$subNet15 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "15" + $environment + "-" + $12oct+([int]$3oct+1)+".224_27") -AddressPrefix ($12oct + ([int]$3oct+1) + ".224/27")
$subNet16 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "16" + $environment + "-" + $12oct+([int]$3oct+2)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".0/26")
$subNet17 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "17" + $environment + "-" + $12oct+([int]$3oct+2)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".64/26")
$subNet18 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "18" + $environment + "-" + $12oct+([int]$3oct+2)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".128/26")
$subNet19 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "19" + $environment + "-" + $12oct+([int]$3oct+2)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+2) + ".192/26")
$subNet20 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "21" + $environment + "-" + $12oct+([int]$3oct+3)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".0/26")
$subNet21 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "21" + $environment + "-" + $12oct+([int]$3oct+3)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".64/26")
$subNet22 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "22" + $environment + "-" + $12oct+([int]$3oct+3)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".128/26")
$subNet23 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "23" + $environment + "-" + $12oct+([int]$3oct+3)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+3) + ".192/26")
$subNet24 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "24" + $environment + "-" + $12oct+([int]$3oct+4)+".0_27") -AddressPrefix	($12oct + ([int]$3oct+4) + ".0/27")
$subNet25 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "25" + $environment + "-" + $12oct+([int]$3oct+4)+".32_27") -AddressPrefix	($12oct + ([int]$3oct+4) + ".32/27")
$subNet26 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "26" + $environment + "-" + $12oct+([int]$3oct+4)+".64_27")-AddressPrefix ($12oct + ([int]$3oct+4) + ".64/27")
$subNet27 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "27" + $environment + "-" + $12oct+([int]$3oct+4)+".96_27") -AddressPrefix ($12oct + ([int]$3oct+4) + ".96/27")
$subNet28 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "28" + $environment + "-" + $12oct+([int]$3oct+4)+".128_27") -AddressPrefix ($12oct + ([int]$3oct+4) + ".128/27")
$subNet29 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "29" + $environment + "-" + $12oct+([int]$3oct+4)+".160_27") -AddressPrefix ($12oct + ([int]$3oct+4) + ".160/27")
$subNet30 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "30" + $environment + "-" + $12oct+([int]$3oct+4)+".192_27") -AddressPrefix ($12oct + ([int]$3oct+4) + ".192/27")
$subNet31 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "31" + $environment + "-" + $12oct+([int]$3oct+4)+".224_27") -AddressPrefix ($12oct + ([int]$3oct+4) + ".224/27")
$subNet32 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "32" + $environment + "-" + $12oct+([int]$3oct+5)+".0_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".0/27")
$subNet33 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "33" + $environment + "-" + $12oct+([int]$3oct+5)+".32_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".32/27")
$subNet34 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "34" + $environment + "-" + $12oct+([int]$3oct+5)+".64_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".64/27")
$subNet35 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "35" + $environment + "-" + $12oct+([int]$3oct+5)+".96_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".96/27")
$subNet36 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "36" + $environment + "-" + $12oct+([int]$3oct+5)+".128_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".128/27")
$subNet37 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "37" + $environment + "-" + $12oct+([int]$3oct+5)+".160_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".160/27")
$subNet38 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "38" + $environment + "-" + $12oct+([int]$3oct+5)+".192_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".192/27")
$subNet39 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "39" + $environment + "-" + $12oct+([int]$3oct+5)+".224_27") -AddressPrefix ($12oct + ([int]$3oct+5) + ".224/27")
$subNet40 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "40" + $environment + "-" + $12oct+([int]$3oct+6)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+6) + ".0/26")
$subNet41 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "41" + $environment + "-" + $12oct+([int]$3oct+6)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+6) + ".64/26")
$subNet42 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "42" + $environment + "-" + $12oct+([int]$3oct+6)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+6) + ".128/26")
$subNet43 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "43" + $environment + "-" + $12oct+([int]$3oct+6)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+6) + ".192/26")
$subNet44 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "44" + $environment + "-" + $12oct+([int]$3oct+7)+".0_26") -AddressPrefix ($12oct + ([int]$3oct+7) + ".0/26")
$subNet45 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "45" + $environment + "-" + $12oct+([int]$3oct+7)+".64_26") -AddressPrefix ($12oct + ([int]$3oct+7) + ".64/26")
$subNet46 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "46" + $environment + "-" + $12oct+([int]$3oct+7)+".128_26") -AddressPrefix ($12oct + ([int]$3oct+7) + ".128/26")
$subNet47 = new-AzureRmVirtualNetworkSubnetConfig -Name($vNetName + "47" + $environment + "-" + $12oct+([int]$3oct+7)+".192_26") -AddressPrefix ($12oct + ([int]$3oct+7) + ".192/26")
#Generate a single variable with the information about all the subnet configurations
$Subnets = $subNet1,$subNet2,$subNet3,$subNet4,$subNet5,$subNet6,$subNet7,$subNet8,$subNet9,$subNet10,$subNet11,$subNet12,$subNet13,$subNet14,$subNet15,$subNet16,$subNet17,$subNet18,$subNet19,$subNet20,$subNet21,$subNet22,$subNet23,$subNet24,$subNet25,$subNet26,$subNet27,$subNet28,$subNet29,$subNet30,$subNet31,$subNet32,$subNet33,$subNet34,$subNet35,$subNet36,$subNet37,$subNet38,$subNet39,$subNet40,$subNet41,$subNet42,$subNet43,$subNet44,$subNet45,$subNet46,$subNet47

#Generate the Virtual Network name with the range and index information
$VnetFullName = $SubName+"SNETVN"+$NumI + "$Environment-"+($Range -replace '/','_')

#Create the virtual network with all the subnet information created above
New-AzureRmVirtualNetwork -ResourceGroupName $Resgroup.ResourceGroupName -Location $region   -Name $VnetFullName -AddressPrefix "$Range" -Subnet $Subnets -DnsServer $dnsserver1,$dnsserver2

}
}

#Menu to select file based or manual input of the variables to be used in the function
write-host "Select the type of data entry you wish to perform"
write-host ""
write-host "1.- Manual input"
write-host "2.- File based input"
write-host ""
$option = read-host "Enter selection"
switch ($option) {
        1{
            $Range = read-host "Enter Range, example: 172.29.180.0/22"
            $Region = read-host "Enter A region, example eastus2"
            $SubName = read-host "Enter the Business Unit of the Subscription, for OIP-NONP it would be OIP" 
            $Environment = read-host "Enter the type of environment P for Prod or Stage, or D for anything else"
            cls
                                write-host "Please confirm the following list of values is correct before proceeding:"
                                write-host ""
                                write-host "Range        $($Range)"
                                write-host "Region       $($Region)"
                                write-host "SubName      $($SubName)"
                                write-host "Environment  $($Environment)"
                                write-host ""
                                read-host "Press Enter to continue"            

        }
        2{
                    Function Get-FileName($initialDirectory){   
                        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
                        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                        $OpenFileDialog.initialDirectory = $initialDirectory
                        $OpenFileDialog.filter = "All files (*.*)| *.*"
                        $OpenFileDialog.ShowDialog() | Out-Null
                        $OpenFileDialog.filename
                    } 
                            #Using the above defined function, get the CSV file with all the parameters
                            $parameters = Import-Csv (Get-FileName -initialDirectory ".\")
                            #Once the user selects the file, assign the values to the parameters
                            $Range = $parameters.Range
                            $Region = $parameters.Region
                            $SubName = $parameters.SubName
                            $Environment = $parameters.Environment
                            

                                #Show confirmation to the user before proceeding
                                write-host "Please confirm the following list of values is correct before proceeding:"
                                write-host ""
                                write-host "Range        $($parameters.Range)"
                                write-host "Region       $($parameters.Region)"
                                write-host "SubName      $($parameters.SubName)"
                                write-host "Environment  $($parameters.Environment)"
                                write-host ""
                                read-host "Press Enter to continue"
        }
}

#Login to azure
Login-AzureRmAccount

#Select subscription to work on
Select-AzureRmSubscription -SubscriptionId (Get-AzureRmSubscription | Out-GridView -Title "Select Azure RM Subscription..." -PassThru).Id 

#Actual call of the function
Create-Networking-For-Range $Range $Region $SubName $Environment

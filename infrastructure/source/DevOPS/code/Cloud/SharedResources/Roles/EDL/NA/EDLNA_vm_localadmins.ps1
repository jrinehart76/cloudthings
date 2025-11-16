net localgroup administrators AM\10thMagnitudeDevOps /add	#don't work'
net localgroup administrators AM\10thMagnitudeSupport /add #don't work
net localgroup administrators elcompanies\U-CUST-A-EDLNAAdmin /add
net localgroup administrators elcompanies\U-CUST-A-EDLGlobalAdmin /add
net localgroup administrators elcompanies\sa-am-tableau-qa /add

net localgroup administrators elcompanies\U-CUST-A-EDLNADev_All /add
net localgroup administrators elcompanies\U-CUST-A-EDLNADev_Fin /add
net localgroup administrators elcompanies\U-CUST-A-EDLNADev_DTC /add
net localgroup administrators elcompanies\U-CUST-A-EDLNADev_HR /add
net localgroup administrators elcompanies\U-CUST-A-EDLNADev_SC /add
net localgroup administrators elcompanies\U-CUST-A-EDLNADev_CsMkt /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_All'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_Fin'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_DTC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_HR'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_SC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_CsMkt'); }"

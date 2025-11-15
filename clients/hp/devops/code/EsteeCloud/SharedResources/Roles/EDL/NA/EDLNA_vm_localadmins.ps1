net localgroup administrators AM\10thMagnitudeDevOps /add	#don't work'
net localgroup administrators AM\10thMagnitudeSupport /add #don't work
net localgroup administrators elcompanies\U-ELC-EDLNAAdmin /add
net localgroup administrators elcompanies\U-ELC-EDLGlobalAdmin /add
net localgroup administrators elcompanies\sa-am-tableau-qa /add

net localgroup administrators elcompanies\U-ELC-EDLNADev_All /add
net localgroup administrators elcompanies\U-ELC-EDLNADev_Fin /add
net localgroup administrators elcompanies\U-ELC-EDLNADev_DTC /add
net localgroup administrators elcompanies\U-ELC-EDLNADev_HR /add
net localgroup administrators elcompanies\U-ELC-EDLNADev_SC /add
net localgroup administrators elcompanies\U-ELC-EDLNADev_CsMkt /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_All'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_Fin'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_DTC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_HR'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_SC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-EDLGlobalDev_CsMkt'); }"

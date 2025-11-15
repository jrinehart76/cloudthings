net localgroup administrators AM\kbrinkle /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-CEPAPAC-Devs'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-ELC-CEPAPAC-Admins'); }"

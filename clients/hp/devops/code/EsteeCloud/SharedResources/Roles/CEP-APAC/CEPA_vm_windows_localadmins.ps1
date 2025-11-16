net localgroup administrators AM\kbrinkle /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-CEPAPAC-Devs'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-CEPAPAC-Admins'); }"

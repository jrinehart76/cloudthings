#!/bin/bash
mkdir /tmp/sources
# Remove DOS line endings, if they exist
for filename in /tmp/sources/*.*; do
    tr -d '\r' < $filename > $filename.2
    rm -f $filename
    mv $filename.2 $filename
    file $filename
done
#
# Update kernel settings
#
sudo mv sysctl.conf /etc/sysctl.conf -f
#
# Update limits
#
sudo mv limits.conf /etc/security/limits.conf -f
#
# Update resolv.conf
#
sudo mv resolv.conf /etc/resolv.conf -f
#
# Prevent overwrite of resolv.conf
#
sudo mv NetworkManager.conf /etc/NetworkManager/NetworkManager.conf -f
#
# Update Azure Agent conf
#
echo "HttpProxy.Host=elcproxy.elcompanies.net" >> /etc/waagent.conf
echo "HttpProxy.Port=9480" >> /etc/waagent.conf
# Need to figure out how to get ResourceDisk.SwapSizeMB= 
#
#
# Mount NFS
#
sudo mv auto.master /etc/auto.master -f
sudo mv auto.direct /etc/auto.direct -f
sudo mv sssd.conf /etc/sssd/sssd.conf -f
chmod 600 /etc/sssd/sssd.conf
sudo mv password-auth-ac.cfg /etc/pam.d/password-auth-ac
systemctl restart sssd
systemctl restart autofs
#
# Update SUDOERS
#
echo $(cat sudoers.add) >> /etc/sudoers
#
# Install SAP Host Agent
#
/sapbasis/SAP_HOST_AGENT/OSS_NOTE_1473974_AUTO_UPGRADE/SAPCAR_LINUX -xvf /sapbasis/SAP_HOST_AGENT/OSS_NOTE_1473974_AUTO_UPGRADE/LINUX/SAPHOSTAGENT41_41-20009394.SAR -R /usr/sap/tmp/

cd /usr/sap/tmp/
/usr/sap/tmp/saphostexec -install
#
# Install Oracle client
#
su oracle
cd /oracle/client
mkdir 12x
cd 12x
/sapbasisazr/software/oracle/client-51052986/SAPCAR -xvf /sapbasisazr/software/oracle/client-51052986/OCL_LINUX_X86_64/OCL12264.SAR

ln -s instantclient_12201 instantclient
#
# END OF SCRIPT
#
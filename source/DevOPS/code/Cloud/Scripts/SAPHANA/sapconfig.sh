#!/bin/bash
HOSTNAME=$(uname -n)
IPADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
#
# Set timezone
#
timedatectl set-timezone UTC
#
# Update hosts
#
echo "$IPADDRESS $HOSTNAME.#{RegionLower}#.elcompanies.net $HOSTNAME" >> /etc/hosts
#
# Update iptables
#
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables -L -n
#
# Stop firewall services
#                    
systemctl stop firewalld
systemctl disable firewalld
#
# Update all packages
#
yum update -y
#
# Install required additional components
#
yum groupinstall large-systems -y
yum groupinstall network-file-system-client -y
yum groupinstall performance -y
yum groupinstall compat-libraries -y
yum groupinstall debugging -y
yum groupinstall directory-client -y
yum groupinstall hardware-monitoring -y
yum groupinstall perl-runtime -y
yum groupinstall x11 -y
yum groupinstall development -y

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

yum install postfix glibc-devel.x86_64 compat-glibc.x86_64 glibc-headers.x86_64 compat-glibc-headers.x86_64 compat-libcap1.x86_64 compat-libtiff3.x86_64 perl-core perl-Module-CoreList compat-sap-c++-6 ncurses-devel -y
yum install compat-sap-c++-5 xterm uuidd openssl libaio-devel.x86_64 ksh compat-libstdc++-33.x86_64 expect graphviz iptraf-ng libcanberra-gtk2 libicu PackageKit-gtk3-module xulrunner gtk2 azure-cli sssd sssd-client sssd-tools openldap-clients policycoreutils-python lm_sensors -y
#
# Set softlinks for SAP Hana
#
ln -s /usr/lib64/libssl.so.0.9.8e /usr/lib64/libssl.so.0.9.8
ln -s /usr/lib64/libssl.so.1.0.1e /usr/lib64/libssl.so.1.0.1
ln -s /usr/lib64/libcrypto.so.0.9.8e /usr/lib64/libcrypto.so.0.9.8
ln -s /usr/lib64/libcrypto.so.1.0.1e /usr/lib64/libcrypto.so.1.0.1
#
# Update GRUB
#
sudo mv grub.default /etc/default/grub -f
grub2-mkconfig -o /boot/grub2/grub.cfg
#
# Disable services
#
systemctl disable abrtd
systemctl disable abrt-ccpp
systemctl stop abrtd
systemctl stop abrt-ccpp
systemctl stop kdump.service
systemctl disable kdump.service
#
# Update SELINUX
#
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#
# Update email Settings
#
echo "hostname = $HOSTNAME.elcompanies.net" >> /etc/postfix/main.cf
echo "mydomain = am.elcompanies.net" >> /etc/postfix/main.cf
echo "relayhost = [mailrelay.am.elcompanies.net]" >> /etc/postfix/main.cf
sed -i 's/smtp      inet  n       -       n       -       -       smtpd/8025      inet  n       -       n       -       -       smtpd/g' /etc/postfix/master.cf
#
# Enable NFS and Automounter
#
systemctl enable nfs-server
systemctl start nfs-server
systemctl enable autofs
systemctl start autofs
#
# Create groups
#
groupadd -g 2000 elcbasis
groupadd -g 2001 sapbasis
groupadd -g 2002 sutemp
groupadd -g 3000 dba
groupadd -g 3001 sapsys
groupadd -g 3002 oper
groupadd -g 3003 sapinst
groupadd -g 3005 oinstall
groupadd -g 3006 sdba
groupadd -g 4000 sapadmusr
groupadd -g 4001 rundeck
groupadd -g 4002 zabbix
groupadd -g 4003 mysql
groupadd -g 4004 asmoper
groupadd -g 4005 asmadmin
groupadd -g 4006 asmdba
#
# Create users
#
useradd -g oinstall -G dba,oper -u 3000 -c "Oracle Administrator" -m -s "/bin/csh" oracle
echo "#{oracle}#" | passwd --stdin oracle
useradd -g sapsys -u 3001 -c "Vertex Administrator" -m -s "/bin/csh" vrtxadm
echo "#{vrtxadm}#" | passwd --stdin vrtxadm
useradd -g sapsys -u 3002 -c "SAP Administrator" -m -s "/bin/csh" lcaadm
echo "#{lcaadm}#" | passwd --stdin lcaadm
useradd -g sdba -u 3003 -c "SAP Administrator" -m -s "/bin/bash" sdb
echo "#{sdb}#" | passwd --stdin sdb
useradd -g sapadmusr -u 4000 -c "SAP Administrator" -m -s "/bin/bash" sapadmusr
echo "#{sapadmusr}#" | passwd --stdin sapadmusr
useradd -g rundeck -u 6000 -c "Rundeck Scheduler" -m -s "/bin/bash" rundeck
echo "#{rundeck}#" | passwd --stdin rundeck
useradd -g zabbix -u 6001 -c "Zabbix Monitoring" -m -s "/bin/bash" zabbix
echo "#{zabbix}#" | passwd --stdin zabbix
useradd -g mysql -u 6002 -c "MySQL Database" -m -s "/bin/bash" mysql
echo "#{mysql}#" | passwd --stdin mysql
useradd -g sapsys -u 3998 -c "SAP Diagnostics Agent" -m -s "/bin/csh" daaadm
echo "#{daaadm}#" | passwd --stdin daaadm
useradd -g sapsys -u 3999 -c "SAP Diagnostics Agent" -m -s "/bin/csh" sapadm
echo "#{sapadm}#" | passwd --stdin sapadm
#
# Create SAP, Oracle and Hana Directories
#
mkdir /sapbasis
chmod 777 /sapbasis
mkdir /sapbasisazr
chmod 777 /sapbasisazr
mkdir /sapbackupazr
chmod 777 /sapbackupazr
	
mkdir /hana
mkdir /hana/shared
mkdir /hana/data
mkdir /hana/log
chmod -R 777 /hana

mkdir /oracle
mkdir /oracle/client
chown -R oracle:oinstall /oracle
chmod -R 777 /oracle

mkdir /sapmnt
chmod 777 /sapmnt
mkdir /usr/sap
chmod 777 /usr/sap
mkdir /usr/sap/trans
chmod 777 /usr/sap/trans
mkdir /usr/sap/trans_elc
chmod 777 /usr/sap/trans_elc
mkdir /usr/sap/DAA
mkdir /usr/sap/tmp
mkdir /usr/sap/hostctrl

mkdir /usr/home
chmod 777 /usr/home
#
# Install HTOP and FIO
#
mkdir /tmp/sources
cd /tmp/sources
git clone https://github.com/hishamhm/htop
cd htop
./autogen.sh && ./configure && make && sudo make install

cd /tmp/sources
git clone https://github.com/axboe/fio
cd fio
./configure && make && sudo make install
# Assuming all installed okay, remove the source Directories
cd /tmp/sources
rm -rf htop
rm -rf fio
#
# Run Authconfig to enable SSSD auth
#
sudo authconfig --enablesssd --enablesssdauth --enablemkhomedir --update
#
# END OF SCRIPT
#

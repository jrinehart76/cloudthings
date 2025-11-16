#!/bin/bash
DOMAIN='am.customer-a-domain.local'
DC1='dc-server.am.customer-a-domain.local'
DCIP1='10.10.10.23'
DC2='dc-server.eu.customer-a-domain.local'
DC2IP='10.10.10.24'
RMV_EXT=${DOMAIN%.*}
RMV_EXT_UPPER=${RMV_EXT^^}
FULL_DOMAIN_UPPER=${DOMAIN^^}
RMV_EXT_DC1=${DC1%.*}
NOEX_DC1=${RMV_EXT_DC1%.*}
RMV_EXT_DC2=${DC2%.*}
NOEX_DC2=${RMV_EXT_DC2%.*}

#### Install required packages ####

echo "Installing required packages"
export DEBIAN_FRONTEND=noninteractive
DEBIAN_FRONTEND=noninteractive apt-get -yq install samba krb5-config krb5-user winbind libpam-winbind libnss-winbind


cp /etc/krb5.conf /etc/krb5.original
truncate -s0 /etc/krb5.conf

#### Modify kerberos configuration ####

echo ..........
echo .......... Modifying Modifying /etc/krb5.conf file ..........
echo ..........
kerb=""
kerb+="[libdefaults] \n"
kerb+="ticket_lifetime = 24000 \n"
kerb+="default_realm = $FULL_DOMAIN_UPPER \n"
kerb+="default_tgs_enctypes = rc4-hmac des-cbc-md5 \n"
kerb+="default_tkt_enctypes = rc4-hmac des-cbc-md5 \n"
kerb+="permitted_enctypes = rc4-hmac des-cbc-md5 \n"
kerb+="dns_lookup_realm = true \n"
kerb+="dns_lookup_kdc = true \n"
kerb+="dns_fallback = yes \n"
kerb+=" \n"
kerb+="[realms] \n"
kerb+="$FULL_DOMAIN_UPPER = { \n"
kerb+="  kdc = $DC1 \n"
kerb+="  default_domain = $DOMAIN \n"
kerb+="} \n"
kerb+=" \n"
kerb+="[domain_realm] \n"
kerb+=".$DOMAIN = $FULL_DOMAIN_UPPER \n"
kerb+="$DOMAIN = $FULL_DOMAIN_UPPER \n"
kerb+=" \n"
kerb+="[appdefaults] \n"
kerb+="pam = { \n"
kerb+="   debug = false \n"
kerb+="   ticket_lifetime = 36000 \n"
kerb+="   renew_lifetime = 36000 \n"
kerb+="   forwardable = true \n"
kerb+="   krb4_convert = false \n"
kerb+="} \n"
kerb+=" \n"
kerb+="[logging] \n"
kerb+="default = FILE:/var/log/krb5libs.log \n"
kerb+="kdc = FILE:/var/log/krb5kdc.log \n"
kerb+="admin_server = FILE:/var/log/kadmind.log \n"

echo -en $kerb >> /etc/krb5.conf

#### Modify samba configuration ####

echo ..........
echo .......... Modifying /etc/samba/smb.conf file ..........
echo ..........
cp -f /etc/samba/smb.conf /etc/samba/smb.conf.original
truncate -s0 /etc/samba/smb.conf
samba4=""
samba4+="[global] \n"
samba4+="   allow trusted domains = Yes"
samba4+="\n"
samba4+="   realm = $FULL_DOMAIN_UPPER \n"
samba4+="   workgroup = $RMV_EXT_UPPER \n"
samba4+="   security = ADS \n"
samba4+="   idmap uid = 10000-20000 \n"
samba4+="   idmap gid = 10000-20000 \n"
samba4+="   template homedir = /home/%D/%U \n"
samba4+="   template shell = /bin/bash \n"
samba4+="   winbind use default domain = yes \n"
samba4+="   winbind offline logon = false \n"
samba4+="   winbind nss info = rfc2307 \n"
samba4+="   winbind separator = + \n"
samba4+="   winbind enum users = yes \n"
samba4+="   winbind enum groups = yes \n"
samba4+="   client use spnego = yes \n"
samba4+="   client ntlmv2 auth = yes \n"
samba4+="   encrypt passwords = yes \n"
samba4+="   restrict anonymous = 2 \n"
samba4+="   valid users = @yakadmins \n"
samba4+="   log file = /var/log/samba/log.%m \n"
samba4+="   max log size = 50 \n"
samba4+="\n"
samba4+="   vfs objects = acl_xattr \n"
samba4+="   map acl inherit = Yes \n"
samba4+="   store dos attributes = Yes \n"
echo -en $samba4 >> /etc/samba/smb.conf


#### Modify local host file ####

echo ..........
echo .......... Modifying hosts file ..........
echo ..........
mv /etc/hosts /etc/hosts.original
hostsfile=""
hostsfile+="127.0.0.1   localhost \n"
hostsfile+="127.0.1.1   $HOSTNAME   $HOSTNAME.$FULL_DOMAIN_UPPER \n"
hostsfile+="$DCIP1      $NOEX_DC1        $DC1 \n"
#hostsfile+="$DCIP2      $NOEX_DC2        $DC2 \n"
hostsfile+="\n"
hostsfile+="# The following lines are desirable for IPv6 capable hosts \n"
hostsfile+="::1 ip6-localhost ip6-loopback \n"
hostsfile+="fe00::0 ip6-localnet \n"
hostsfile+="ff00::0 ip6-mcastprefix \n"
hostsfile+="ff02::1 ip6-allnodes \n"
hostsfile+="ff02::2 ip6-allrouters \n"
hostsfile+="ff02::3 ip6-allhosts \n"
echo -en $hostsfile >> /etc/hosts


#### Update DHCP client to add internal DNS ####

echo ..........
echo .......... Modifying DHClient to add local DNS servers and domain name ..........
echo ..........
sed -i 's/#supersede domain-name "fugue.com home.vix.com";/supersede domain-name "'"$DOMAIN"'" "'"$DOMAIN"'";/' /etc/dhcp/dhclient.conf
sed -i 's/#prepend domain-name-servers 127.0.0.1;/prepend domain-name-servers "'"$DCIP1"'";/' /etc/dhcp/dhclient.conf
echo ..........
echo .......... RESTARTING networking service ..........
echo ..........
sudo systemctl restart networking.service
echo ..........
echo .......... ALTERING sshd_config ..........
echo ..........
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo UseDNS no >> /etc/ssh/sshd_config
echo ..........
echo .......... RESTARTING sshd service ..........
echo ..........
service sshd restart


#### Modify PAM to set up home directory creation ####

echo ..........
echo .......... Modifying pam.d/sshd to create home directory upon login ..........
echo ..........
echo "# Create home directory upon login" >> /etc/pam.d/sshd_config
sudo echo "session     required        pam_mkhomedir.so skel=/etc/skel/" >> /etc/pam.d/sshd

#### Modify NSSWitch file to allow winbind auth ####

echo ..........
echo .......... adding winbind to /etc/nsswitch.conf ..........
echo ..........
cp /etc/nsswitch.conf /etc/nsswitch.conf.old
truncate -s0 /etc/nsswitch.conf

nsw=""
nsw+="passwd:         files winbind \n"
nsw+="group:          files winbind \n"
nsw+="shadow:         files winbind \n"
nsw+="gshadow:        files \n"
nsw+=" \n"
nsw+="hosts:          files dns \n"
nsw+="networks:       files \n"
nsw+=" \n"
nsw+="protocols:      db files \n"
nsw+="services:       db files \n"
nsw+="ethers:         db files \n"
nsw+="rpc:            db files \n"
nsw+=" \n"
nsw+="netgroup:       nis \n"
nsw+="sudoers:        files"

echo -e "\n$nsw" >> /etc/nsswitch.conf 

echo ...........................................
echo ...........................................
echo Ready to join $domain 
echo ... join via:  
echo ... sudo kinit [username] 
echo ... sudo net ads join -S $DC1 -U [username]
echo ...........................................
echo ...........................................
#!/bin/bash 
# 10M
# Domain join realmd/sssd
# Example: ./join_domain.sh EU.ELCOMPANIES.NET sa-us-svcmycloud@AM.ELCOMPANIES.NET <password> g-am-cloudops@am.elcompanies.net "OU=Azure,OU=ELC Servers,DC=eu,DC=elcompanies,DC=net"

set -xe
IFS='|'

VERSION_ID=$(lsb_release -r | awk {'print $2'})
DOMAIN_TO_JOIN=$1
DOMAIN_JOIN_USER=$2
DOMAIN_JOIN_USER_DOMAIN=$(echo $DOMAIN_JOIN_USER | cut -d'@' -f2 | tr [:lower:] [:upper:] )
DOMAIN_JOIN_PASSWORD=$3
PERMIT_GROUPS=$4
COMPUTER_OU=$5


usage () {
if [ -z $DOMAIN_TO_JOIN ] ; then
  echo "$(basename $0) domain_to_join domain_join_user domain_join_password permit_groups computer_ou"
  exit 1
fi
}

resolv_test () {
  if [ -L /etc/resolv.conf ] || [ -f /etc/resolv.conf ] ; then
    echo "Found resolv.conf"
  elif [ -f /run/systemd/resolve/stub-resolv.conf ] ; then
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
  else
    echo "Cannot find resolver config"
  fi

  if [ -f /usr/bin/host ] && [ -z $DOMAIN_TO_JOIN ] ; then
    host $DOMAIN_TO_JOIN
  fi
}


apt_wait () {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
    while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
      sleep 1
    done
  fi
}

install_prerequisites () {
  apt-get update
  apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
}

realm_discovery () {
  realm discover $DOMAIN_TO_JOIN
  realm discover $DOMAIN_JOIN_USER_DOMAIN
}

domain_join () {

 if [ ! -f /var/lib/sss/pubconf/kdcinfo.$DOMAIN_JOIN_USER_DOMAIN ] ; then
   LOCAL_AD_SITE=$(adcli info $DOMAIN_JOIN_USER_DOMAIN | grep computer-site | awk {'print $3'})
   dig +short $(dig +short -t SRV _ldap._tcp.$LOCAL_AD_SITE._sites.$DOMAIN_JOIN_USER_DOMAIN | awk {'print $4'}) > /var/lib/sss/pubconf/kdcinfo.$DOMAIN_JOIN_USER_DOMAIN
 fi

 realm join --computer-ou="$COMPUTER_OU" --user=$DOMAIN_JOIN_USER $DOMAIN_TO_JOIN --verbose <<< $DOMAIN_JOIN_PASSWORD

}

permit_groups () {
 realm permit -g $PERMIT_GROUPS
}

apt_wait

usage
case $VERSION_ID in
  18.04)
    #echo "Ubuntu 18.04"
    resolv_test
    install_prerequisites
    realm_discovery
    domain_join
    permit_groups
    ;;

  16.04)
    #echo "Ubunutu 16.04"
    resolv_test
    install_prerequisites
    realm_discovery
    domain_join
    permit_groups
    ;;
  *)
    echo "Unknown release"
    exit 1
    ;;
esac
#!/bin/bash
# Check for the existence of the user
checkadmin=`cat /etc/passwd | grep cloudadmin`
if [ "$checkadmin" = "" ]
then
  adduser --shell /bin/bash cloudadmin
  echo 'User created.'
else
  echo 'User exists.'
fi
# Make sure the user is in the sudoers file
checksudoers=`cat /etc/sudoers | grep cloudadmin`
if [ "$checksudoers" = "" ]
then
  echo 'cloudadmin  ALL=(ALL)  NOPASSWD: ALL' >> /etc/sudoers
  echo 'User updated in sudoers file.'
else
  echo 'User exists in sudoers file.'
fi

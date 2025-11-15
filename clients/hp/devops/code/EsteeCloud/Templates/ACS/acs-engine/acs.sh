#!/bin/bash

sed -i "s/search reddog.microsoft.com/search reddog.microsoft.com #{InternalDns}#/g" /etc/resolv.conf
echo "search reddog.microsoft.com #{InternalDns}#" > /etc/resolvconf/resolv.conf.d/base
echo "#{FirstConsecutiveIP}# #{ClusterDnsPrefix}#.#{Location}#.cloudapp.azure.com" >> /etc/hosts
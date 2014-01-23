#!/usr/bin/bash

set -x

userdata=`wget -q -O - http://169.254.169.254/latest/user-data`; if [ -n "$(echo "$userdata" | grep '^#!')" ]; then echo "$userdata" | sh; fi
hostname=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`

set -e

if [ -z "$hostname" ]
then
	hostname=storage
fi

if [ -e variables ]
then
	echo "variables file does not exist. Please refer to the documentation on how to obtain the file."
fi

. ./variables

export hostname
export domain
export domain_hostname
export domain_admin_pass
export domain_admin_user
export nameserver
export basedn
export binduser
export bindpass
export ldapservers

hostname $hostname

cat > /etc/nodename <<EOF
$hostname
EOF

cat > /etc/hosts <<EOF
::1             localhost
127.0.0.1       localhost
127.0.0.1       $hostname.$domain	$hostname	loghost
EOF

sh ./ldapclient_setup.sh
sleep 10

cat > /etc/nsswitch.conf <<EOF
passwd:         files ldap
group:          files ldap
hosts:          dns files
ipnodes:        dns files
networks:       files
protocols:      files
rpc:            files
ethers:         files
netmasks:       files
bootparams:     files
publickey:      files
netgroup:       files
automount:      files
aliases:        files
services:       files
printers:       user files
auth_attr:      files
prof_attr:      files
project:        files
tnrhtp:         files
tnrhdb:         files
EOF

svccfg import resolv-conf.xml
svccfg import idmap.xml
cp dns-resolv-conf /lib/svc/method
chmod a+x /lib/svc/method/dns-resolv-conf

svccfg -s resolv-conf setprop 'options/domain="'$domain'"'
svccfg -s resolv-conf setprop 'options/search="'$domain_hostname.$domain'"'
svccfg -s resolv-conf setprop 'options/nameserver="'$nameserver'"'

svcadm refresh resolv-conf
svcadm disable svc:/network/dns/resolv-conf:default
svcadm enable svc:/network/dns/resolv-conf:default
svcadm restart svc:/network/dns/client
svcadm disable ntp
sleep 10

ntpdate $domain_hostname.$domain
echo -e "driftfile /etc/inet/ntp.drift\nserver $domain_hostname.$domain" > /etc/inet/ntp.conf ; svcadm enable ntp

sharectl set -p lmauth_level=2 smb
sharectl set -p signing_enabled=true smb
svccfg -s svc:/system/idmap setprop config/directory_based_mapping=astring: idmu
set nfssrv:nfs_portmon = 1

./adjoin.exp 
sleep 10

./smbjoin.exp
sleep 10

svcadm disable idmap smb/server
sleep 4
svcadm enable -r smb/server
sleep 2

idmap remove -a
idmap add 'winuser:*' 'unixuser:*'
idmap add winuser:$domain_admin_user@$domain unixuser:root

reboot

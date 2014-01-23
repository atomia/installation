# Configuring Nexenta for use with Atomia #

Before you start make sure the following steps work

1. Make sure Netbios is turned on the DC. Client for Microsoft Networks is on and File/Printer Sharing is On in network control panels.
 
SSH to the nexentastore server as root

		# Go into expert mode
		nmc@nexenta:/$ option expert_mode=1
		nmc@nexenta:/$ !bash

		# Set preferred domain controller
		sharectl set -p pdc=IPDADDRESSOFSERVER smb
		sharectl set -p lmauth_level=2 smb

		# Test if dns is working 
		dig _ldap._tcp.dc._msdcs.yourdomain.local SRV +short
		# If the command above does not return the SRV records of your domain you can not proceed before this is fixed

		# Set NFSMAPID_DOMAIN in /etc/default/nfs
		vim /etc/default/nfs
		# Specifies to nfsmapid daemon that it is to override its default
		# behavior of using the DNS domain, and that it is to use 'domain' as
		# the domain to append to outbound attribute strings, and that it is to
		# use 'domain' to compare against inbound attribute strings.
		NFSMAPID_DOMAIN=yourdomain.local

		# Join the domain
		mkdir /root/atomiasetup
		cd /root/atomiasetup
		wget https://github.com/atomia/installation/raw/master/Storage/Nexenta/package.tar.gz && tar -xvf package.tar.gz
		cd adjoin
		./set_variables.sh
		apt-get install ldap-utils
		cd adjoin
		./adjoin -f
		cd ../
		./ldapclient_setup.sh
		smbadm join -u Administrator yourdomain.local

		# Set up idmapping
		idmap remove -a
		idmap add 'winuser:*' 'unixuser:*'
		idmap add winuser:Administrator@yourdomain.local unixuser:root

		zfs set nbmand=on storage/content
		zfs set nbmand=on storage/configuration
		zfs set casesensitivity=mixed storage/content
		zfs set casesensitivity=mixed storage/configuration

		chmod -R 711 webdata/

		# Restart nfs services
 		svcadm restart svc:/network/nfs/mapid
  		svcadm restart svc:/network/nfs/server
  		svcadm restart svc:/network/nfs/client



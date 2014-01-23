#!/bin/sh
. ./variables
ldapclient manual \
		   -a credentialLevel=proxy \
		   -a authenticationMethod=simple \
		   -a proxyDN=cn="$binduser,$basedn" \
		   -a proxyPassword="$bindpass" \
		   -a defaultSearchBase="$basedn" \
		   -a domainName="$domain" \
		   -a defaultServerList="$ldapservers" \
		   -a attributeMap=group:userpassword=userPassword \
		   -a attributeMap=group:memberuid=memberUid \
		   -a attributeMap=group:gidnumber=gidNumber \
		   -a attributeMap=passwd:gecos=cn \
		   -a attributeMap=passwd:gidnumber=gidNumber \
		   -a attributeMap=passwd:uidnumber=uidNumber \
		   -a attributeMap=passwd:homedirectory=unixHomeDirectory \
		   -a attributeMap=passwd:loginshell=loginShell \
		   -a attributeMap=shadow:shadowflag=shadowFlag \
		   -a attributeMap=shadow:userpassword=userPassword \
		   -a objectClassMap=group:posixGroup=group \
		   -a objectClassMap=passwd:posixAccount=user \
		   -a objectClassMap=shadow:shadowAccount=user \
		   -a serviceSearchDescriptor=passwd:"$basedn"?sub \
		   -a serviceSearchDescriptor=group:"$basedn"?sub

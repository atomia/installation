#!/bin/ksh

#
# ident "@(#)adjoin.sh	1.0	08/01/01 SMI"
#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#


PROG=${0#*/}

PATH=/usr/sbin:/usr/bin:$PATH:/opt/sfw/bin
grep=/usr/xpg4/bin/grep

fatal ()
{
    print -u2 "$PROG: Fatal error: $*"
    exit 9
}

usage ()
{
    cat <<EOF
Usage: adjoin  [options] [domain [nodename]]
Usage: adleave [options] [domain [nodename]]

	Joins or leaves an Active Directory domain.  This includes:
	
	 o deleting a Computer object in AD
	 o creating a Computer object in AD
	 o setting its password to a randomized password
	 o creating /etc/krb5/krb5.conf
	 o creating /etc/krb5/krb5.keytab with keys based on the
	   computer password

	The administrator MUST make sure that:

	 - /etc/resolv.conf is setup properly, which, if the AD domain
	   has not been delegated, means:

	    + only nameservers for that domain must be used in resolv.conf

	   Creating a useful search list is recommended.

	 - /etc/nsswitch.conf says "files dns" for 'hosts' and 'ipnodes'.

	Options:

	-h	This message

	-n	Dry-run (don't do anything)
	-v	Verbose (show the commands run and objects created/modified)

	-i	Ignore any pre-existing computer account for this host;
		change its keys.
	-r	Reset  any pre-existing computer account for this host
		and change its keys.
	-f	Delete any pre-existing computer account for this host.
	-f -f	Delete any pre-existing computer account for this host
		and objects contained by it.

	-d ...	Name of a domain controller to use.  If not given one
		will be found.  Note: this MUST be a domain controller
		in the domain being joined and it MUST also be a global
		catalog server [Default: discover one]
	-p ...	Name of an administrator principal to use for creating
		the computer account [default: Administrator]

	Other options:

	-o ...  Container where to put machine account [Default: CN=Computers]
	-x	Debug (set -x and typeset -ft for all functions)

	Examples:

		$PROG -p joe.admin example.com
EOF
    exit 1
}

got_tix=false

cleanup ()
{
    $got_tix && kdestroy
    $got_tix && rm -f "$KRB5CCNAME"
    [[ -n "$object" ]] && rm -f "$object"
}

trap "cleanup" EXIT

# Convert a DNS domainname to an AD-style DN for that domain
dns2dn ()
{
    typeset OIFS dn labels

    OIFS="$IFS"
    IFS=.
    set -A labels -- $1
    IFS="$OIFS"

    dn=
    for label in "${labels[@]}"
    do
	dn="${dn},DC=$label"
    done

    print -- "${dn#,}"
}

# Convert an AD-style domain DN to a DNS domainname
dn2dns ()
{
    typeset OIFS dname dn comp components

    dn=$1
    dname=

    OIFS="$IFS"
    IFS=,
    set -A components -- $1
    IFS="$OIFS"

    for comp in "${components[@]}"
    do
	[[ "$comp" = [dD][cC]=* ]] || continue
	dname="$dname.${comp#??=}"
    done

    print ${dname#.}
}

# Form a base DN from a DNS domainname and container
getBaseDN ()
{
    if [[ -n "$2" ]]
    then
	baseDN="CN=$1,$(dns2dn $2)"
    else
	baseDN="$(dns2dn $2)"
    fi
}


# Resolve a domainname to its canonical name, and shorten it if possible
#
# (Short names are preferred only for testing, so we can have a DNS
# domain for AD that is not actually delegated by its parent -- as long
# as /etc/resolv.conf points to an AD DNS server and those have the same
# name in the AD domain and in the parent, then we can properly derive
# service principal names from the short form name, but not from the
# long-form, thus we prefer the short form.)
canon_resolve ()
{
    typeset ip fqdn

    $verbose dig -t a "$1" +short 1>&2
    dig -t a "$1" +short|read ip

    [[ -z "$ip" ]] && return 1

    $verbose dig -x $ip +short 1>&2
    dig -x $ip +short|read fqdn

    [[ -n "$(dig -t a "${fqdn%%.*}" +short +search)" ]] && fqdn=${fqdn%%.*}

    print -- "$fqdn"
}

discover_domain ()
{
    typeset keyword d dig_args
    dig_args="+search +noall +answer +ndots=4"
    dig _ldap._tcp.dc._msdcs srv $dig_args|grep ^_ldap|while read rrname junk
    do
	dom=${rrname#_ldap._tcp.dc._msdcs.}
	dom=${dom%.}
	return 0
    done
    return 1
}

check_nss_hosts_or_ipnodes_config ()
{
    typeset backend

    for backend in $1
    do
	[[ "$backend" = dns ]] && return 0
    done
    return 1
}

check_nss_conf ()
{
    typeset i j hosts_config

    for i in hosts ipnodes
    do
	grep "^${i}:" /etc/nsswitch.conf|read j hosts_config
	check_nss_hosts_or_ipnodes_config "$hosts_config" || return 1
    done

    return 0
}

ipAddr2num ()
{
    typeset OIFS
    typeset -i16 num byte

    if [[ "$1" != +([0-9]).+([0-9]).+([0-9]).+([0-9]) ]]
    then
	print 0
	return 0
    fi

    OIFS="$IFS"
    IFS=.
    set -- $1
    IFS="$OIFS"

    num=$((${1}<<24 | ${2}<<16 | ${3}<<8 | ${4}))

    print -- $num
}

num2ipAddr ()
{
    typeset -i16 num
    typeset -i10 a b c d

    num=$1
    a=$((num>>24        ))
    b=$((num>>16 & 16#ff))
    c=$((num>>8  & 16#ff))
    d=$((num     & 16#ff))
    print -- $a.$b.$c.$d
}

netmask2length ()
{
    typeset -i16 netmask
    typeset -i len

    netmask=$1
    len=32
    while [[ $((netmask % 2)) -eq 0 ]]
    do
	netmask=$((netmask>>1))
	len=$((len - 1))
    done
    print $len
}

getSubnets ()
{
    typeset -i16 addr netmask
    ifconfig -a|while read line
    do
	addr=0
	netmask=0
	set -- $line
	[[ "$1" = inet ]] || continue
	while [[ $# -gt 0 ]]
	do
	    case "$1" in
		inet) addr=$(ipAddr2num $2); shift;;
		netmask) eval netmask=16\#$2; shift;;
		*) :;
	    esac
	    shift
	done

	[[ $addr -eq 0 || $netmask -eq 0 ]] && continue
	[[ $((addr & 16\#ff000000)) -eq 16\#7f000000 ]] && continue

	print $(num2ipAddr $((addr & netmask)))/$(netmask2length $netmask)
    done
}

getSite ()
{
    typeset subnet siteDN j ldapsrv subnet_dom

    eval "[[ -n \"\$siteName\" ]]" && return
    for subnet in $(getSubnets)
    do
	print "\tLooking for subnet object in the global catalog"
	$verbose ldapsearch -R -T -h $dc $ldap_args \
		-p 3268 -b "" -s sub cn=$subnet dn
	ldapsearch -R -T -h $dc $ldap_args \
		-p 3268 -b "" -s sub cn=$subnet dn |grep ^dn|read j subnetDN

	[[ -z "$subnetDN" ]] && continue
	print "\tLooking for subnet object in its domain"
	subnet_dom=$(dn2dns $subnetDN)
	ldapsrv=$(canon_resolve DomainDnsZones.$subnet_dom)
	$verbose ldapsearch -R -T -h $ldapsrv $ldap_args \
	    -b "$subnetDN" -s base "" siteObject
	ldapsearch -R -T -h $ldapsrv $ldap_args \
	    -b "$subnetDN" -s base "" siteObject |grep ^siteObject|read j siteDN

	[[ -z "$siteDN" ]] && continue

	eval siteName=${siteDN%%,*}
	eval siteName=\${siteName#CN=}
	return
    done

    print "Could not find site name for any local subnet"
}

doKRB5config ()
{
    if $do_config
    then
	if [[ -f /etc/krb5/krb5.conf ]]
	then
	    $verbose cp /etc/krb5/krb5.conf /etc/krb5/krb5.conf-pre-adjoin
	    $dryrun cp /etc/krb5/krb5.conf /etc/krb5/krb5.conf-pre-adjoin
	fi

	if [[ -f /etc/krb5/krb5.keytab ]]
	then
	    $verbose cp /etc/krb5/krb5.keytab /etc/krb5/krb5.keytab-pre-adjoin
	    $dryrun cp /etc/krb5/krb5.keytab /etc/krb5/krb5.keytab-pre-adjoin
	fi

	$verbose cp $KRB5_CONFIG /etc/krb5/krb5.conf
	$dryrun cp $KRB5_CONFIG /etc/krb5/krb5.conf
	$verbose chmod 0644 /etc/krb5/krb5.conf
	$dryrun chmod 0644 /etc/krb5/krb5.conf
	$verbose cp $new_keytab /etc/krb5/krb5.keytab
	$dryrun cp $new_keytab /etc/krb5/krb5.keytab
	$verbose chmod 0600 /etc/krb5/krb5.keytab
	$dryrun chmod 0600 /etc/krb5/krb5.keytab
    else
	cat <<EOF
	Kerberos V configuration file is in $KRB5_CONFIG; please edit and
	install into /etc/krb5/krb5.conf.

	The new keytab is in $new_keytab; please install into
	/etc/krb5/krb5.keytab."
EOF
    fi
}

doIDMAPconfig ()
{
    if svcs -l svc:/system/idmap > /dev/null 2>&1
    then
	# SNV/OpenSolaris
	if $leave
	then
	    $verbose svcadm disable -s svc:/system/idmap
	    $notdryrun && svcadm disable -s svc:/system/idmap
	else
	    $verbose svcadm disable -ts svc:/system/idmap
	    $notdryrun && svcadm disable -ts svc:/system/idmap
	    $verbose svcadm enable -t svc:/system/idmap
	    $notdryrun && svcadm enable -t svc:/system/idmap
	fi
    else
	# S10
	return 0
    fi
}

getSRVs ()
{
    typeset srv port query
    [[ -n "$dnssrv" ]] && dig_arg1="@$dnssrv"
    $verbose dig $dig_arg1 "$1" SRV +short 1>&2
    dig $dig_arg1 "$1" SRV +short|sort -n|while read j j port srv
    do
	print -- ${srv%.} $port
    done
}

getGC ()
{
    typeset j

    [[ -n "$gc" ]] && return 0

    if [[ -n "$siteName" ]]
    then
	set -A GCs -- $(getSRVs _ldap._tcp.$siteName._sites.gc._msdcs.$forest.)
	gc=${GCs[0]}
	[[ -n "$gc" ]] && return
    fi

    # No site name
    set -A GCs -- $(getSRVs _ldap._tcp.gc._msdcs.$forest.)
    gc=${GCs[0]}
    [[ -n "$gc" ]] && return

    # Default
    set -A GCs -- $ForestDnsZones 3268
    gc=$ForestDnsZones
}

getDC ()
{
    typeset j

    if [[ -n "$siteName" ]]
    then
	set -A DCs -- $(getSRVs _ldap._tcp.$siteName._sites.dc._msdcs.$dom.)
	dc=${DCs[0]}
	[[ -n "$dc" ]] && return
    fi

    # No site name
    set -A DCs -- $(getSRVs _ldap._tcp.dc._msdcs.$dom.)
    dc=${DCs[0]}
    [[ -n "$dc" ]] && return

    # Default
    set -A DCs -- $DomainDnsZones 389
    dc=$DomainDnsZones
}

getKDC ()
{
    typeset j

    set -A KPWs -- $(getSRVs _kpasswd._tcp.$dom.)
    kpasswd=${KPWs[0]}

    if [[ -n "$siteName" ]]
    then
	set -A KDCs -- $(getSRVs _kerberos._tcp.$siteName._sites.$dom.)
	kdc=${KDCs[0]}
	[[ -n "$kdc" ]] && return
    fi

    # No site name
    set -A KDCs -- $(getSRVs _kerberos._tcp.$dom.)
    kdc=${KDCs[0]}
    [[ -n "$kdc" ]] && return

    # Default
    set -A KDCs -- $DomainDnsZones 88
    kdc=$ForestDnsZones

}

getForestName ()
{
    $verbose ldapsearch -R -T -h $dc $ldap_args \
	    -b "" -s base "" schemaNamingContext
    ldapsearch -R -T -h $dc $ldap_args \
	    -b "" -s base "" schemaNamingContext| \
		grep ^schemaNamingContext|read j schemaNamingContext
    schemaNamingContext=${schemaNamingContext#CN=Schema,CN=Configuration,}

    [[ -z "$schemaNamingContext" ]] && return 1

    forest=
    while [[ -n "$schemaNamingContext" ]]
    do
	schemaNamingContext=${schemaNamingContext#DC=}
	forest=${forest}.${schemaNamingContext%%,*}
	[[ "$schemaNamingContext" = *,* ]] || break
	schemaNamingContext=${schemaNamingContext#*,}
    done
    forest=${forest#.}
}

write_krb5_conf ()
{
    cf=$(mktemp -t -p /tmp adjoin-krb5.conf.XXXXXX)
    chmod 644 "$cf"

    (
    cat <<EOF
[libdefaults]
	default_realm = $realm

[realms]
	$realm = {
EOF
    for i in ${KDCs[@]}
    do
	[[ "$i" = +([0-9]) ]] && continue
	print "\t\tkdc = $i"
    done

    #
    # We also add admin_server entry because it's required
    # by kpasswd(1) till CR6629530 is fixed.
    #
    cat <<EOF
		kpasswd_server = $kpasswd
		kpasswd_protocol = SET_CHANGE
		admin_server = $kpasswd
	}

[domain_realm]
	.$dom = $realm
EOF
    ) > "$cf"
    print "$cf"
}

err ()
{
    [[ $# -lt 1 ]] && exit 1
    ret=${1}
    shift
    print -u2 -- "$@"
    exit $ret
}

ldap_args="-o authzid= -o mech=gssapi"

typeset -l dc
typeset -l dom
typeset -l nodename
typeset -u upcase_nodename
join=:
dc=
dom=
osvers=$(uname -r)
port=3268
site=
force=false
extra_force=false
baseDN=
dnssrv=
cprinc=Administrator
dryrun=
notdryrun=:
nodename=
verbose=:
do_config=:
container=Computers
debug_shell=false
verbose_cat=:
userAccountControlBASE=4096
modify_existing=false
ignore_existing=false
add_account=:

leave=false
[[ "${PROG}" == adleave ]] && leave=:
while [[ $# -gt 0 && "$1" = -* ]]
do
    case "$1" in
	-h) usage;;
	-d) dc=$2; shift;;
	-D) dnssrv=$2; shift;
	    [[ "$dnssrv" = +([0-9.:, ]) ]] || usage;;
	-p) cprinc=$2; shift;;
	-s) site=$2; shift;;
	-i) ignore_existing=:; modify_existing=false;;
	-r) add_account=false; force=false; extra_force=false; modify_existing=:;;
	-f) add_account=:; modify_existing=false; $force && extra_force=:; force=:;;
	-n) dryrun=:; notdryrun=false;;
	-x) typeset -ft $(typeset +f); set -x;;
	-v) verbose='print \t'; verbose_cat=cat;;
	-o) container=$2; shift;;
	-X) debug_shell=:; return;;
	-*) usage;;
    esac
    shift
done

nodename=$(uname -n)
if [[ $# -gt 0 ]]
then
    dom=${1%.}
    shift
    if [[ $# -gt 0 ]]
    then
	    nodename=$1
	    shift
    fi
    [[ $# -gt 0 ]] && usage
else
    if discover_domain
    then
	print "Joining domain: $dom"
    else
	print "No domain was specified and one could not be discovered."
	print "Please Check you DNS resolver configuration"
	exit 1
    fi
fi

check_nss_conf || err 1 "/etc/nsswitch.conf does not make use of DNS for hosts and/or ipnodes"

upcase_nodename=$nodename
netbios_nodename="${upcase_nodename}\$"
fqdn=${nodename}.$dom
[[ $# -gt 0 ]] && usage

print "Looking for domain controllers and global catalogs (A RRs)"
DomainDnsZones=$(canon_resolve DomainDnsZones.$dom.)
ForestDnsZones=$(canon_resolve ForestDnsZones.$dom.)

typeset -u realm
realm=$dom

getBaseDN "$container" "$dom"

print "Looking for KDCs and DCs (SRV RRs)"
getKDC
getDC
cat <<EOF
	KDCs = ${KDCs[*]}
	DCs = ${DCs[*]}
EOF

export KRB5_CONFIG=$(write_krb5_conf)
export KRB5CCNAME=$(mktemp -t -p /tmp adjoin-krb5ccache.XXXXXX)
new_keytab=$(mktemp -t -p /tmp adjoin-krb5keytab.XXXXXX)

if [[ -z "$cprinc" ]]
then
	print -n "Enter administrator principal name: "
	read cprinc || exit 1
fi

$verbose kinit "$cprinc"
$dryrun kinit "$cprinc" || err 1 "Could not get a Kerberos V TGT for your admin principal"
$dryrun eval got_tix=:

# Lookups involving LDAP searches, for which we need krb5 tix
print "Looking for forest name"
if getForestName
then
    print "\tForest name = $forest"
else
    fatal "\tForest name not found!  There's probably a bug."
    print "\tAssume forest name == domainname"
    forest=$dom
fi
print "Looking for Global Catalog servers"
getGC
print "Looking for site name"
getSite

# Re-do SRV lookups now that we have a site name
if [[ -z "$siteName" ]]
then
    print "\tSite name not found.  Local DCs/GCs will not be discovered"
else
    print "Looking for _local_ KDCs, DCs and global catalog servers (SRV RRs)"
    getKDC
    getDC
    getGC
    cat <<EOF
	Local KDCs = ${KDCs[*]}
	Local DCs  = ${DCs[*]}
	Local GCs  = ${GCs[*]}
EOF
fi

if [[ ${#GCs} -eq 0 ]]
then
    print "Could not find global catalogs.  Exiting"
fi

print "Looking to see if there's an existing account..."
$verbose ldapsearch -R -T -h "$dc" $ldap_args -b "$baseDN" \
	-s sub sAMAccountName="$netbios_nodename" dn
if $notdryrun
then
    if ldapsearch -R -T -h "$dc" $ldap_args -b "$baseDN" \
	-s sub sAMAccountName="$netbios_nodename" dn > /dev/null 2>&1
    then
	:
    else
	fatal "ldapsearch failed -- something's wrong"
    fi
    ldapsearch -R -T -h "$dc" $ldap_args -b "$baseDN" -s sub \
	sAMAccountName="$netbios_nodename" dn|grep "^dn:"|read j dn
fi

if [[ -z "$dn" ]]
then
    ignore_existing=false
    modify_existing=false
fi

if [[ $ignore_existing = false && $modify_existing = false && -n "$dn" ]]
then
    print "Looking to see if the machine account contains other objects..."
    ldapsearch -R -T -h "$dc" $ldap_args -b "$dn" -s sub "" dn | while read j sub_dn
    do
	[[ "$j" != dn: || -z "$sub_dn" || "$dn" = "$sub_dn" ]] && continue
	if $extra_force
	then
	    print "Deleting the following object: ${sub_dn#$dn}"
	    ldapdelete -h "$dc" $ldap_args "$sub_dn"
	elif $ignore_existing
	then
	    :
	else
	    print "The following object must be deleted (use -f -f, -r or -i): ${sub_dn#$dn}"
	fi
    done

    if $force  || $leave
    then
	print "Deleting existing machine account..."
	$verbose ldapdelete -h "$dc" $ldap_args "$dn"
	ldapdelete -h "$dc" $ldap_args "$dn"
    elif $modify_existing || $ignore_existing
    then
	:
    else
	print "A machine account already exists! (try -i, -r or -f; see usage)"
	exit 1
    fi
fi

if $leave
then
	doIDMAPconfig
	print -- "$PROG: Done"
	exit 0
fi

object=$(mktemp -t -p /tmp adjoin-computer-object.XXXXXX)

##
## Main course
##
#
#  The key here are the userPrincipalName, servicePrincipalName and
#  userAccountControl attributes.  Note that servicePrincipalName must
#  not have the @REALM part while userPrincipalName must have it.  And
#  userAccountControl MUST NOT have the DONT_REQ_PREAUTH flag (unless
#  krb5.conf is going to be written so we always do pre-auth) -- no
#  pre-auth, no LDAP lookups.
#


if $modify_existing
then
    cat > "$object" <<EOF
dn: CN=$upcase_nodename,$baseDN
changetype: modify
replace: servicePrincipalName
servicePrincipalName: host/${fqdn}
-
replace: userAccountControl
userAccountControl: $((userAccountControlBASE + 32 + 2))
-
replace: dNSHostname
dNSHostname: ${fqdn}
EOF

    print "A machine account already exists; resetting it..."
    $verbose ldapadd -h "$dc" $ldap_args -f "$object"
    $dryrun ldapadd -h "$dc" $ldap_args -f "$object" || \
	err 1 "Could not add the new object to AD"

elif $ignore_existing
then
    print "A machine account already exists; re-using it..."
else
    cat > "$object" <<EOF
dn: CN=$upcase_nodename,$baseDN
objectClass: computer
cn: $upcase_nodename
sAMAccountName: ${netbios_nodename}
userPrincipalName: host/${fqdn}@${realm}
servicePrincipalName: host/${fqdn}
userAccountControl: $((userAccountControlBASE + 32 + 2))
dNSHostname: ${fqdn}
EOF

    print "Creating the machine account in AD via LDAP"
    $verbose_cat "$object"

    $verbose ldapadd -h "$dc" $ldap_args -f "$object"
    $dryrun ldapadd -h "$dc" $ldap_args -f "$object" || \
	err 1 "Could not add the new object to AD"

    if [[ $? -ne 0 ]]
    then
	    print "Failed to create the AD object via LDAP"
	    exit 1
    fi
fi

# Generate a new password for the new account
print "Setting the password/keys of the machine account"
while :
do
	newpw=$(dd if=/dev/random of=/dev/fd/1 bs=16 count=1 2>/dev/null |
		od -t x1 | head -1 | cut -d\  -f2-17 | sed 's/ //g')
	[[ "$newpw" = +([0-9a-zA-Z]) ]] && break
done

# Set the new password
#
# We add one uppercase letter so we pass the password quality check
# (three character classes!)
newpw=A$newpw
$verbose "print $newpw | ./ksetpw host/${fqdn}@${realm}"
if $notdryrun
then
    print "$newpw" | ./ksetpw host/${fqdn}@${realm}

    if [[ $? -ne 0 ]]
    then
	print "Failed to set account password!"
	exit $?
    fi
fi


# Lookup the new principal's kvno:
print "Getting kvno"
$verbose ldapsearch -R -T -h "$dc" $ldap_args -b "$baseDN" \
	-s sub cn=$upcase_nodename msDS-KeyVersionNumber

if $notdryrun
then
	ldapsearch -R -T -h "$dc" $ldap_args -b "$baseDN" \
		-s sub cn=$upcase_nodename msDS-KeyVersionNumber| \
		grep "^msDS-KeyVersionNumber"|read j kvno
	# Default kvno
	[[ -z "$kvno" ]] && kvno=1
	print "KVNO: $kvno"
else
	print "(dryrun) KVNO would likely be: 1"
fi

# Set supported enctypes.  This only works for Longhorn/Vista, so we
# ignore errors here.
userAccountControl=$((userAccountControlBASE + 524288 + 65536))
set -A enctypes --

arcfour=false
des=false
if [[ "$osvers" == "5.11" ]]
then
	# Check local support for AES?
	encrypt -l|grep ^aes|read j minkeysize maxkeysize

	# Check local support for ARCFOUR?
	encrypt -l|$grep -q ^arcfour && arcfour=:

	# Check local support for DES?
	encrypt -l|$grep -q ^des && des=:
else
	# Check local support for AES?
	cryptoadm list -v mechanism=CKM_AES_CBC 2>/dev/null | \
		$grep ^CKM_AES_CBC | read j minkeysize maxkeysize j
	# Convert bytesize into bitsize
	minkeysize=$((minkeysize * 8))
	maxkeysize=$((maxkeysize * 8))

	# Check local support for ARCFOUR?
	cryptoadm list -m provider=arcfour 2>/dev/null \
		| $grep CKM_RC4 >/dev/null 2>&1 && arcfour=:
	[[ $arcfour == false ]] && cryptoadm list -m provider=arcfour2048 \
		2>/dev/null | $grep CKM_RC4 >/dev/null 2>&1 && arcfour=:

	# Check local support for DES?
	cryptoadm list -m provider=des 2>/dev/null \
		| $grep CKM_DES_ >/dev/null 2>&1 && des=:
fi
val=
if [[ $minkeysize -eq 128 && $maxkeysize -eq 256 ]]
then
	val=00000018
	aes128=:
	aes256=:
elif [[ $minkeysize -eq 128 ]]
then
	val=00000008
	aes128=:
	aes256=false
elif [[ $maxkeysize -eq 256 ]]
then
	val=00000010
	aes128=false
	aes256=:
else
	aes128=false
	aes256=false
fi

print "Determining supported enctypes for machine account via LDAP"
cat > "$object" <<EOF
dn: CN=$upcase_nodename,$baseDN
changetype: modify
add: msDS-SupportedEncryptionTypes
msDS-SupportedEncryptionTypes: $val
EOF
$verbose ldapmodify -h "$dc" $ldap_args -f "$object"
$verbose_cat "$object"
$dryrun ldapmodify -h "$dc" $ldap_args \
	-f "$object" >/dev/null 2>&1
if [[ $? -ne 0 ]]
then
	aes128=false
	aes256=false
	print "This must not be a Longhorn/Vista AD DC!"
	print "\tSo we assume 1DES and arcfour enctypes"
else
	print "This must a Longhorn/Vista AD DC."
fi

# Add the strongest enctypes first to the enctypes[] array
$aes256 && enctypes[${#enctypes[@]}]=aes256-cts-hmac-sha1-96
$aes128 && enctypes[${#enctypes[@]}]=aes128-cts-hmac-sha1-96

$aes256 && print "AES-256 will be supported"

# Arcfour comes next (whether it's better than 1DES or not -- AD prefers it)
if $arcfour
then
	enctypes[${#enctypes[@]}]=arcfour-hmac-md5
	print "ARCFOUR will be supported"
else
	# Use 1DES ONLY if we don't have arcfour
	userAccountControl=$((userAccountControl + 2097152))
	print "ARCFOUR will NOT be supported"
fi
if $des
then
	enctypes[${#enctypes[@]}]=des-cbc-crc
	enctypes[${#enctypes[@]}]=des-cbc-md5
fi

if [[ ${#enctypes[@]} -eq 0 ]]
then
	print "No enctypes are supported!"
	print "Please enable arcfour or 1DES, then re-join; see cryptoadm(1M)"
	exit 1
fi

# We should probably check whether arcfour is available, and if not,
# then set the 1DES only flag, but whatever, it's not likely NOT to be
# available on S10/Nevada!

# Reset userAccountControl
#
#  NORMAL_ACCOUNT (512) | DONT_EXPIRE_PASSWORD (65536) |
#  TRUSTED_FOR_DELEGATION (524288)
#
# and possibly UseDesOnly (2097152) (see above)
#
print "Finishing machine account"
cat > "$object" <<EOF
dn: CN=$upcase_nodename,$baseDN
changetype: modify
replace: userAccountControl
userAccountControl: $userAccountControl
EOF
$verbose ldapmodify -h "$dc" $ldap_args -f "$object"
$verbose_cat "$object"
$dryrun ldapmodify -h "$dc" $ldap_args -f "$object"

# Setup a keytab file
set -A args --
for enctype in "${enctypes[@]}"
do
	args[${#args[@]}]=-e
	args[${#args[@]}]=$enctype
done
rm "$new_keytab"
print "$newpw"|./ksetpw -n -v $kvno -k "$new_keytab" "${args[@]}" host/${fqdn}@${realm}

doKRB5config

doIDMAPconfig

print -- "$PROG: Done"
exit 0

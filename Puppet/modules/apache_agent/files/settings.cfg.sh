#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "usage: $0 user pass ssl|nossl"
	exit 1
fi

if [ x"$3" = x"ssl" ]; then
	ssl="True"
else
	ssl="False"
fi

cat <<EOF
[settings]
SERVER_WEB_ROOT             = /storage/content
VHOSTS_MAP_FILE             = /storage/configuration/maps/vhost.map
USERS_MAP_FILE              = /storage/configuration/maps/users.map
PARKING_MAP_FILE            = /storage/configuration/maps/parks.map
REDIRECTION_MAP_FILE        = /storage/configuration/maps/redrs.map
FRAME_REDIRECTION_MAP_FILE  = /storage/configuration/maps/frmrs.map
SUSPENDED_MAP_FILE          = /storage/configuration/maps/sspnd.map
PACKAGE_MAP_FILE            = /storage/configuration/maps/packg.map
PHPVERSION_MAP_FILE         = /storage/configuration/maps/phpvr.map
SERVICE_PORT                = 9999
SSL_CONFIG_DIR              = /etc/apache2/ssl.d
SSL_CERT_DIR                = /storage/configuration/ssl
APACHECTL_PATH              = /usr/sbin/apache2ctl
SERVICE_AUTH                = True
SERVICE_AUTH_USER           = $1
SERVICE_AUTH_PW             = $2
SERVE_HTTPS                 = $ssl
CERTIFICATE_FILE            = /usr/local/apache-agent/wildcard.crt
PRIVATE_KEY_FILE            = /usr/local/apache-agent/wildcard.key
EOF


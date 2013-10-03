#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: $0 user pass"
        exit 1
fi

cat <<EOF
FS_STORAGE_PATH=/storage/configuration
FS_STORAGE_BACKUP_PATH=/storage/content_backup
FS_ROOT_DIRS_PATTERNS=^/ssl$
FS_ARBITRARY_DIRS_PATTERNS=^/awstats-sites$
FS_USERNAME=$1
FS_PASSWORD=$2
FS_PARENT_ACCOUNT=100000
FS_ADD_GROUP=33
FS_AGENT_PORT=10202
EOF


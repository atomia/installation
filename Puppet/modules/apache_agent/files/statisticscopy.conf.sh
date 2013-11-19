#!/bin/sh

cat <<EOF
copy_source_path = /var/log/apache2
copy_temp_path = /storage/content/logs/copy_in_progress
copy_destination_path = /storage/content/logs/to_be_merged
filename_filter = access\.\d+\.log
lsof_path = /usr/bin/lsof
cluster_node_name = $1
EOF


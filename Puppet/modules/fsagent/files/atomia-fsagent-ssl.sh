#!/bin/sh
cat <<EOF
#!/bin/sh

### BEGIN INIT INFO
# Provides:          fsagent-server
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $network $syslog
# Should-Stop:       $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start and stop fsagent-server.
# Description:       Atomia File System agent
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

[ ! -f /etc/default/fsagent-ssl ] || . /etc/default/fsagent-ssl
export FS_STORAGE_PATH FS_STORAGE_BACKUP_PATH FS_ROOT_DIRS_PATTERNS FS_ARBITRARY_DIRS_PATTERNS FS_USERNAME FS_PASSWORD FS_PARENT_ACCOUNT FS_ADD_GROUP FS_AGENT_PORT

. /lib/lsb/init-functions
DISTRO=$(lsb_release -is 2>/dev/null || echo Debian)

case "\$1" in
    start)
	log_daemon_msg "Starting Atomia fsagent-ssl-server." "fsagent-server-ssl"

	if start-stop-daemon --start --background --make-pidfile --pidfile /var/run/atomia-fsagent-ssl.pid \
				--startas /bin/sh -- -c "atomia-fsagent-server 2>&1 | logger -t fsagent-server-ssl"; then
	    log_end_msg 0
	else
	    log_end_msg 1
	fi
	
    ;;

    stop)
	log_daemon_msg "Stopping Atomia fsagent-ssl-server." "fsagent-server-ssl"

	if sh -c "ps axwwj | grep '/bin/sh -c atomia-fsagent-server' | grep -v grep | awk '{ print \$4 }' | xargs -r pkill -g"; then
	    log_end_msg 0
	else
	    log_end_msg 1
	fi
	
    ;;

    restart)
	$0 stop
	sleep 1
	$0 start
    ;;
    
    *)
	log_action_msg "Usage: $0 {start|stop}"
	exit 1
    ;;
esac
exit 0
EOF


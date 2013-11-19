class postfix_mx (
		$provisioning_host,
		$atomia_mail_db_is_master,
		$atomia_mail_storage_nfs_location,
		$atomia_mail_master_ip,
		$atomia_mail_agent_password,
		$mail_slave_password,
		$mail_server_id,
		$no_nfs_config = 0
	){
	package { postfix-mysql: ensure => installed }
	package { dovecot-common: ensure => installed }
	package { libmime-encwords-perl: ensure => installed }
	package { libemail-valid-perl: ensure => installed }
	package { libmail-sendmail-perl: ensure => installed }
	package { liblog-log4perl-perl: ensure => installed }
	package { libdbd-mysql-perl: ensure => installed }
	package { dovecot-imapd: ensure => installed }
	package { dovecot-pop3d: ensure => installed }
	package { dovecot-mysql: ensure => installed }
	
	package { amavisd-new: ensure => installed }
	package { spamassassin: ensure => installed }
	package { clamav-daemon: ensure => installed }

	package { libnet-dns-perl: ensure => installed }
	package { pyzor: ensure => installed }
	package { razor: ensure => installed }
	
        package { arj: ensure => installed }
        package { bzip2: ensure => installed }
        package { cabextract: ensure => installed }
        package { cpio: ensure => installed }
        package { file: ensure => installed }
        package { gzip: ensure => installed }
        package { lha: ensure => installed }
	package { nomarch: ensure => installed } 
	package { pax: ensure => installed } 
	package { rar: ensure => installed } 	
	package { unrar: ensure => installed } 
	package { unzip: ensure => installed } 
	package { zip: ensure => installed } 
	package { zoo: ensure => installed } 

	if $no_nfs_config == 0 {
		include mailnfsmount
	}

	$db_hosts = $ipaddress 
	$db_user = "vmail"
	$db_user_smtp = "smtp_vmail"
	$db_user_dovecot = "dovecot_vmail"
	$db_name = "vmail"
	$db_pass = $atomia_mail_agent_password

	$mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"

	if $atomia_mail_db_is_master == 1{
                class { '::mysql::server':
                        override_options  => { 'mysqld' => {'server_id' => "$mail_server_id", 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => "$db_name", 'bind_address' => $atomia_mail_master_ip}}
                }

                exec { 'grant-replicate-privileges':
                        command => "$mysql_command -e \"GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY '$mail_slave_password';FLUSH PRIVILEGES\";",
                        unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'slave_user'\" mysql | /bin/grep slave_user",
			require => Class[Mysql::Server::Service]
                }

                exec { 'create-postfix-db':
                        command => "$mysql_command -e \"CREATE DATABASE $db_name\"",
                        unless => "$mysql_command -e \"SHOW DATABASES;\" | /bin/grep $db_name",
			require => Class[Mysql::Server::Service]
                }

                exec { 'import-schema':
                        command => "$mysql_command $db_name < /etc/postfix/mysql.schema.sql",
                        unless => "$mysql_command -e \"use $db_name; show tables;\" | /bin/grep user",
			require => Class[Mysql::Server::Service]
                }

                exec { 'grant-postfix-db-user-privileges':
			command => "$mysql_command -e \"CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_pass';GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%'\"",
			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user' \" mysql | /bin/grep $db_user",
			require => Class[Mysql::Server::Service]
		}

                exec { 'grant-postfix-provisioning-user-privileges':
			command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO 'postfix_agent'@'$provisioning_host' IDENTIFIED BY '$db_pass'\"",
			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'postfix_agent' AND host = '$provisioning_host'\" mysql | /bin/grep postfix_agent",
			require => Class[Mysql::Server::Service]
		}


                exec { 'grant-postfix-smtp-db-user-privileges':
			command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO '$db_user_smtp'@'%' IDENTIFIED BY '$db_pass'\"",
			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user_smtp' AND host = '%'\" mysql | /bin/grep $db_user_smtp",
			require => Class[Mysql::Server::Service]
		}

                exec { 'grant-postfix-dovecpt-db-user-privileges':
			command => "$mysql_command -e \"GRANT ALL ON $db_name.* TO '$db_user_dovecot'@'%' IDENTIFIED BY '$db_pass'\"",
			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$db_user_dovecot' AND host = '%'\" mysql| /bin/grep $db_user_dovecot",
			require => Class[Mysql::Server::Service]
		}

	}
 	else {
                # Slave config
                class { 'mysql::server':
                        override_options => { mysqld => { 'server_id' => "$mail_server_id", 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => "$db_name",'bind_address' => "$ipaddress" } }
                }

                exec { 'change-master':
                        command => "$mysql_command -e \"CHANGE MASTER TO MASTER_HOST='$atomia_mail_master_ip',MASTER_USER='slave_user', MASTER_PASSWORD='$mail_slave_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=107\" ;START SLAVE;",
                        unless => "$mysql_command -e \"SHOW SLAVE STATUS\" | grep slave_user",
			require => Class[Mysql::Server::Service]
                }
        }

	file { "/etc/postfix/mysql.schema.sql":
		owner   => root,
		group   => root,
		mode    => 444,
		source  => "puppet:///modules/postfix_mx/mysql.schema.sql",
		require => Package["postfix-mysql"]
	}
	if !$atomia_mailman_installed {
	
		file { "/etc/postfix/main.cf":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/postfix_mx/main.cf",
			require => Package["postfix-mysql"]
		}
	}

	file { "/etc/postfix/master.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		source  => "puppet:///modules/postfix_mx/master.cf",
		require => Package["postfix-mysql"]
	}

	$generator = "/etc/puppet/modules/postfix_mx/files/generate_postfix_mysql.sh"

	$relay_domains_maps = generate($generator, $db_hosts, $db_name, $db_user, $db_pass, "SELECT domain FROM domain WHERE domain = '%s' AND transport = 'relay'")

	file { "/etc/postfix/mysql_relay_domains_maps.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $relay_domains_maps,
		require => Package["postfix-mysql"]
	}

	$virtual_alias_maps = generate($generator, $db_hosts, $db_name, $db_user, $db_pass, "SELECT goto FROM alias WHERE email = '%s'")

	file { "/etc/postfix/mysql_virtual_alias_maps.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $virtual_alias_maps,
		require => Package["postfix-mysql"]
	}

	$virtual_domains_maps = generate($generator, $db_hosts, $db_name, $db_user, $db_pass, "SELECT domain FROM domain WHERE domain = '%s' AND transport = 'dovecot'")

	file { "/etc/postfix/mysql_virtual_domains_maps.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $virtual_domains_maps,
		require => Package["postfix-mysql"]
	}

	$virtual_mailbox_maps = generate($generator, $db_hosts, $db_name, $db_user, $db_pass, "SELECT maildir FROM user WHERE email = '%s'")

	file { "/etc/postfix/mysql_virtual_mailbox_maps.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $virtual_mailbox_maps,
		require => Package["postfix-mysql"]
	}

	$virtual_transport = generate($generator, $db_hosts, $db_name, $db_user, $db_pass, "SELECT transport FROM domain WHERE domain = '%s'")

	file { "/etc/postfix/mysql_virtual_transport.cf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $virtual_transport,
		require => Package["postfix-mysql"]
	}

	$dovecot_mysql = generate("/etc/puppet/modules/postfix_mx/files/generate_dovecot_mysql.sh", $db_hosts, $db_name, $db_user, $db_pass)

	file { "/etc/dovecot/dovecot-sql.conf":
		owner   => root,
		group   => root,
		mode    => 444,
		content	=> $dovecot_mysql,
		require => Package["dovecot-common"],
	}

	file { "/etc/dovecot/dovecot.conf":
		owner   => root,
		group   => root,
		mode    => 444,
		source  => "puppet:///modules/postfix_mx/dovecot.conf",
		require => Package["dovecot-common"],
	}

	file { "/usr/bin/vacation.pl":
		owner   => root,
		group   => virtual,
		mode    => 750,
		source  => "puppet:///modules/postfix_mx/vacation.pl",
	}

	file { "/var/log/vacation.log":
		owner   => virtual,
		group   => virtual,
		mode    => 640,
		ensure	=> present,
	}
	
	file { "/etc/mailname":
		owner => root,
		group => root,
		mode => 444,
		content => $hostname,
		ensure => present,
	}
	
	exec { "gen-key":
		command	=> "/usr/bin/openssl genrsa -out /etc/dovecot/ssl.key 2048; chown root:root /etc/dovecot/ssl.key; chmod 0700 /etc/dovecot/ssl.key",
		creates => "/etc/dovecot/ssl.key",
		provider => "shell"
	}
	
	exec { "gen-csr":
		command	=> "/usr/bin/openssl req -new -batch -key /etc/dovecot/ssl.key -out /etc/dovecot/ssl.csr",
		creates => "/etc/dovecot/ssl.csr",
	}
	
	exec { "gen-cert":
		command	=> "/usr/bin/openssl x509 -req -days 3650 -in /etc/dovecot/ssl.csr -signkey /etc/dovecot/ssl.key -out /etc/dovecot/ssl.crt",
		creates => "/etc/dovecot/ssl.crt",
	}

	service { postfix:
			name => postfix,
			enable => true,
			ensure => running,
			subscribe => [ Package["postfix-mysql"], File["/etc/postfix/main.cf"], File["/etc/postfix/master.cf"] ]
	}

	service { dovecot:
			name => dovecot,
			enable => true,
			ensure => running,
			subscribe => [ Package["dovecot-common"], File["/etc/dovecot/dovecot.conf"], File["/etc/dovecot/dovecot-sql.conf"] ]
	}

	# Configure Spam and Virus filtering

	user { 'clamav':
		ensure => 'present',
		groups => 'amavis',
	}
	user { 'amavis':
                ensure => 'present',
                groups => 'clamav',
        }

	exec { "enable-spamd":
		command => "/bin/sed -i /etc/default/spamassassin -e 's/ENABLED=0/ENABLED=1/' && /bin/sed -i /etc/default/spamassassin -e 's/CRON=0/CRON=1/' ",
	}

	service { "spamassassin":
		enable => true,
		ensure => running
	}

	service { "amavis":
		enable => true,
		ensure => running,
		subscribe => [ File["/etc/amavis/conf.d/15-content_filter_mode"] ],
	}
	
	file { "/etc/amavis/conf.d/15-content_filter_mode":
                owner   => root,
                group   => root,
                mode    => 644,
                source  => "puppet:///modules/postfix_mx/15-content_filter_mode",
        }
}


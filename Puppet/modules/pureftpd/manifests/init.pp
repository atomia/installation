class pureftpd (
	$pureftpd_agent_user,
	$pureftpd_agent_password,
	$pureftpd_master_ip,
	$provisioning_host,
	$pureftpd_password,
	$ftp_cluster_ip,
        $use_nfs3,
        $atomia_web_content_mount_point,
        $atomia_web_content_nfs_location,
        $atomia_web_config_mount_point,
        $atomia_web_config_nfs_location,
        $apache_conf_dir,
        $atomia_iis_config_nfs_location,
        $iis_config_dir,
	$atomia_pureftp_db_is_master,
	$pureftpd_slave_password,
	$ssl_enabled = 0
	){
	package { pure-ftpd-mysql: ensure => installed }

	include nfsmount

#       	class { 'atomia_mysql':
#        	      mysql_username => $pureftpd_agent_user,
#                      mysql_password => $pureftpd_agent_password,
#                      provisioning_host => $provisioning_host,
#                }

	$mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"
        class { 'mysql':
        }
	
	if $atomia_pureftp_db_is_master == 1{

		class { 'mysql::server':
			config_hash => { 'server_id' => '1', 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => 'pureftpd', 'bind_address' => $pureftpd_master_ip}
		}

		exec { 'grant-replicate-privileges':
			command => "$mysql_command -e \"GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY '$pureftpd_slave_password'\";FLUSH PRIVILEGES;",
			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'slave_user'\" mysql | grep slave_user",
		}
		
		exec { 'create-pureftpd-db': 
			command => "$mysql_command -e \"CREATE DATABASE pureftpd\"",
			onlyif => "$mysql_command -e \"SHOW SLAVE HOSTS;\" | grep 1",
			unless => "$mysql_command -e \"SHOW DATABASES;\" | grep pureftpd",
		}

		exec { 'import-schema':
			command => "$mysql_command pureftpd < /etc/pure-ftpd/mysql.schema.sql",
			unless => "$mysql_command -e \"use pureftpd; show tables;\" | grep users",
		}
	
		exec { 'grant-pureftpd-agent-privileges':
		command => "$mysql_command -e \"GRANT ALL ON pureftpd.* TO '$pureftpd_agent_user'@'%' IDENTIFIED BY '$pureftpd_agent_password'\"",
		unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$pureftpd_agent_user' AND host = '%'\" mysql | grep $pureftpd_agent_user",
	}	

#		mysql::db { 'pureftpd':
#  			user     => $pureftpd_db_user,
#  			password => $pureftpd_db_password,
#  			host     => $provisioning_host,
#  			grant    => ['all'],
#  			sql 	 => '/etc/pure-ftpd/mysql.schema.sql',
#  			require  => [ File["/etc/pure-ftpd/mysql.schema.sql"], Package["mysql-server"] ],
#		}

	
#		exec { 'create-pureftpd-user':
#			command => "$mysql_command -e \"GRANT ALL ON pureftpd.* TO 'pureftpd'@'%' IDENTIFIED BY '$pureftpd_password'\"",
#			unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'pureftpd' AND host = '%'\" mysql | grep pureftpd",
#		}

		file { "/etc/pure-ftpd/mysql.schema.sql":
			owner   => root,
			group   => root,
			mode    => 400,
			source  => "puppet:///modules/pureftpd/mysql.schema.sql",
			require => Package["pure-ftpd-mysql"],
		}
	}
	else {
		# Slave config
                class { 'mysql::server':
                        config_hash => { 'server_id' => '2', 'log_bin' => '/var/log/mysql/mysql-bin.log', 'binlog_do_db' => 'pureftpd'}
                }
                exec { 'change-master':
                        command => "$mysql_command -e \"CHANGE MASTER TO MASTER_HOST='$pureftpd_master_ip',MASTER_USER='slave_user', MASTER_PASSWORD='$pureftpd_slave_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=285\" ;START SLAVE;",
                        unless => "$mysql_command -e \"SHOW SLAVE STATUS\" | grep slave_user",
                }
	}
                exec { 'grant-pureftpd-privileges':
                command => "$mysql_command -e \"GRANT ALL ON pureftpd.* TO 'pureftpd'@'127.0.0.1' IDENTIFIED BY '$pureftpd_password'\"",
                unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = 'pureftpd' AND host = '127.0.0.1'\" mysql | grep pureftpd",
        }

	$mysql_conf = generate("/etc/puppet/modules/pureftpd/files/generate_mysql.sh", $pureftpd_master_ip, 'pureftpd', 'pureftpd', $pureftpd_password)
	file { "/etc/pure-ftpd/db/mysql.conf":
		owner   => root,
		group   => root,
		mode    => 400,
		content => $mysql_conf,
		require => Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/ChrootEveryone":
		owner   => root,
		group   => root,
		mode    => 444,
		content => "yes",
		require => Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/CreateHomeDir":
		owner   => root,
		group   => root,
		mode    => 444,
		content => "yes",
		require => Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/DontResolve":
		owner   => root,
		group   => root,
		mode    => 444,
		content => "yes",
		require => Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

	file { "/etc/pure-ftpd/conf/MaxClientsNumber":
		owner   => root,
		group   => root,
		mode    => 444,
		content => "150",
		require => Package["pure-ftpd-mysql"],
		notify	=> Service["pure-ftpd-mysql"],
	}

        file { "/etc/pure-ftpd/conf/DisplayDotFiles":
                owner   => root,
                group   => root,
                mode    => 444,
                content => "yes",
                require => Package["pure-ftpd-mysql"],
                notify  => Service["pure-ftpd-mysql"],
        }
		
		file { "/etc/pure-ftpd/conf/PassivePortRange":
                owner   => root,
                group   => root,
                mode    => 444,
                content => "49152 65534",
                require => Package["pure-ftpd-mysql"],
                notify  => Service["pure-ftpd-mysql"],
        }

        file { "/etc/pure-ftpd/conf/LimitRecursion":
                owner    => root,
                group    => root,
                mode     => 444,
                content  => "15000 15",
                require => Package["pure-ftpd-mysql"],
                notify  => Service["pure-ftpd-mysql"],
	}
        file { "/etc/pure-ftpd/conf/ForcePassiveIP":
                owner    => root,
                group    => root,
                mode     => 444,
                content  => "$ftp_cluster_ip",
                require => Package["pure-ftpd-mysql"],
                notify  => Service["pure-ftpd-mysql"],
        }               



        service { pure-ftpd-mysql:
                name => pure-ftpd-mysql,
		pattern => "pure-ftpd.*",
                enable => true,
                ensure => running,
                subscribe => [ Package["pure-ftpd-mysql"], File["/etc/pure-ftpd/db/mysql.conf"], File["/etc/pure-ftpd/conf/ChrootEveryone"], File["/etc/pure-ftpd/conf/CreateHomeDir"], File["/etc/pure-ftpd/conf/DontResolve"], File["/etc/pure-ftpd/conf/PassivePortRange"] ],
        }

	if $ssl_enabled != 0 {
	        file { "/etc/ssl":
			ensure => directory,
			owner => "root",
			group => "root",
			mode  => 0600,
		}

		file { "/etc/ssl/private":
			ensure => directory,
			owner => "root",
			group => "root",
			mode  => 0600,
		}

		file { "/etc/ssl/private/pure-ftpd.pem":
			owner => "root",
			group => "root",
			mode  => 600,
			content => "$ssl_cert_key$ssl_cert_file",
		}

	        file { "/etc/pure-ftpd/conf/TLS":
			owner   => root,
			group   => root,
			mode    => 444,
			content => "1",
			require => Package["pure-ftpd-mysql"],
			notify  => Service["pure-ftpd-mysql"],
		}
	}
}


$mysql_command = "mysql --defaults-file=/etc/mysql/debian.cnf -Ns"


define mysql_database($name, $schema_table, $initial_schema) {
	exec { "create-db $name":
		command => "$mysql_command -e 'CREATE DATABASE $name'",
		unless => "/usr/bin/test -d $mysql_datadir/$name",
	}

	exec { "import-schema $name":
		command => "$mysql_command $name < $initial_schema",
		unless => "$mysql_command -e \"SELECT * FROM $schema_table\" $name",
	}
}

define mysql_user($name, $host, $db_grant, $password, $grant_option) {
	case $grant_option {
		true: { $grant_statement = " WITH GRANT OPTION" }
		default: { $grant_statement = "" }
	}

	exec { $name:
		command => "$mysql_command -e \"GRANT ALL ON $db_grant.* TO '$name'@'$host' IDENTIFIED BY '$password'$grant_statement\"",
		unless => "$mysql_command -e \"SELECT user, host FROM user WHERE user = '$name' AND host = '$host'\" mysql | grep $name",
	}
}

class atomia_mysql (
	$mysql_username,
	$mysql_password,
	$provisioning_host
	){
	$mysql_datadir = "/var/lib/mysql/data"
	$mysql_command = "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -Ns"

	package { mysql-server: ensure => installed }

	package { apache2: ensure => present }
	package { libapache2-mod-php5: ensure => present }
	package { phpmyadmin: ensure => present }

        service { apache2:
                name => apache2,
                enable => true,
                ensure => running,
        }

	service { "mysql":
                name => "mysql",
                enable => true,
                ensure => running,
                subscribe => [ Package["mysql-server"] ]
	}

	exec { "setup-grants":
		path => "/usr/bin",
		command => "$mysql_command -e \"DELETE FROM user WHERE user = ''; DELETE FROM user WHERE user = 'root'; FLUSH PRIVILEGES;\" mysql", 
		onlyif => "/usr/bin/mysql -u root -e 'SHOW STATUS'",
	}

	file { "/tmp/fix-debian-maint.sh":
		owner => root,
		group => root,
		source => "puppet:///modules/atomia_mysql/fix-debian-maint.sh",
		mode => '777',
	}
	exec { "fix-debian-maint":
		command => "/bin/sh /tmp/fix-debian-maint.sh",
		unless => "$mysql_command -e \"SHOW GRANTS FOR 'debian-sys-maint'@'localhost'\" | grep ALL"
	}
	

	exec { "delete-test-db":
		command => "$mysql_command -e \"DROP DATABASE test;\" ",
		onlyif => "$mysql_command -e \"SHOW DATABASES;\" | grep test"
	}

	# Create provisioning user
	exec { "create-provisioning-user":
		command => "$mysql_command -e \"CREATE USER '$mysql_username'@'$provisioning_host' IDENTIFIED BY '$mysql_password'; GRANT ALL PRIVILEGES ON *.* TO '$mysql_username'@'$provisioning_host'  WITH GRANT OPTION; FLUSH PRIVILEGES;\"",
		unless => "$mysql_command -e \"use mysql; select * from user where User='$mysql_username';\" | grep $mysql_username"
	}

	file { "/etc/cron.hourly/ubuntu-mysql-fix":
                owner   => root,
                group   => root,
                mode    => 500,
                source  => "puppet:///modules/atomia_mysql/ubuntu-fix",
	}

	file { "/etc/security/limits.conf":
		   owner   => root,
		   group   => root,
		   mode    => 644,
		   source  => "puppet:///modules/atomia_mysql/limits.conf",
	}

	file { "/etc/phpmyadmin/config.inc.php":
		owner   => root,
		group   => root,
		mode    => 444,
		source  => "puppet:///modules/atomia_mysql/config.inc.php",
		require => Package["phpmyadmin"],
	}

	file { "/etc/apache2/sites-available/phpmyadmin-default":
		owner   => root,
		group   => root,
		mode    => 444,
		source  => "puppet:///modules/atomia_mysql/default",
		require => Package["apache2"],
	}
    
    file { "/etc/apache2/sites-enabled/phpmyadmin-default":
        owner   => root,
		group   => root,
		mode    => 444,
        ensure => link,
        target => "/etc/apache2/sites-available/phpmyadmin-default",
        require => File["/etc/apache2/sites-available/phpmyadmin-default"],
        notify	=> Service["apache2"],
    }


	if !defined(File['/etc/apache2/sites-enabled/000-default']) {
	        file { "/etc/apache2/sites-enabled/000-default":
			ensure  => absent,
			require => Package["apache2"],
			notify => Service["apache2"],
		}
        }

	if !defined(File['/etc/apache2/sites-available/default']) {
	        file { "/etc/apache2/sites-available/default":
			ensure  => absent,
			require => Package["apache2"],
			notify => Service["apache2"],
		}
        }

        file { "/etc/php5/apache2/php.ini":
               owner   => root,
               group   => root,
               mode    => 644,
               source  => "puppet:///modules/atomia_mysql/php.ini",
               require => Package["apache2"],
               notify  => Service["apache2"],
        }

        exec { "force-reload-apache-phpmyadmin":
                refreshonly => true,
                before => Service["apache2"],
                command => "/etc/init.d/apache2 force-reload",
        }

        exec { "/usr/sbin/a2enmod php5":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/php5.load",
                require => Package["libapache2-mod-php5"],
                notify => Exec["force-reload-apache-phpmyadmin"],
        }

#	file { "/etc/mysql/my.cnf":
#		   owner   => root,
#		   group   => root,
#		   mode    => 644,
#		   source  => "puppet:///modules/mysql/my.cnf",
#	}
	
#	if !defined(File[$mysql_datadir]) {
#		file { $mysql_datadir:
#			  ensure => directory,
#			  owner => "mysql",
#			  group => "mysql",
#			  require => Package["mysql-server"],
#		}
#	}
}


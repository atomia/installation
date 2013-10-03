class apache_agent (
	 $ssl_enabled = 0,
	 $atomia_clustered = 1,
	 $apache_agent_user,
	 $apache_agent_password,
	$use_nfs3,
        $atomia_web_content_mount_point,
        $atomia_web_content_nfs_location,
        $atomia_web_config_mount_point,
        $atomia_web_config_nfs_location,
        $apache_conf_dir,
        $atomia_iis_config_nfs_location,
        $iis_config_dir
	){
	if $atomia_linux_software_auto_update {
	        package { atomia-pa-apache: ensure => latest }
	        package { atomiastatisticscopy: ensure => latest }
	} else {
	        package { atomia-pa-apache: ensure => present }
	        package { atomiastatisticscopy: ensure => present }
	}

	if !defined(Package['apache2']) {
        	package { apache2: ensure => present }
	}

        package { libapache2-mod-fcgid-atomia: ensure => present }
        package { apache2-suexec-custom-cgroups-atomia: ensure => present }
        package { php5-cgi: ensure => present }
        package { libexpat1: ensure => installed }
	package { cgroup-bin: ensure => installed }

	# PHP extensions except for default
	package { php5-gd: ensure => installed }
	package { php5-imagick: ensure => installed }
	package { php5-sybase: ensure => installed }
	package { php5-mysql: ensure => installed }
	package { php5-odbc: ensure => installed }
	package { php5-curl: ensure => installed }
	package { php5-pgsql: ensure => installed }

    include nfsmount

	if $ssl_enabled != 0{
		$ssl_generate_var = "ssl"

	        file { "/usr/local/apache-agent/wildcard.key":
        	        owner   => root,
                	group   => root,
	                mode    => 440,
         	        content => $ssl_cert_key,
                	require => Package["atomia-pa-apache"],
	                notify => Service["atomia-pa-apache"],
        	}

	        file { "/usr/local/apache-agent/wildcard.crt":
        	        owner   => root,
                	group   => root,
	                mode    => 440,
        	        content => $ssl_cert_file,
                	require => Package["atomia-pa-apache"],
	                notify => Service["atomia-pa-apache"],
        	}
	} else {
		$ssl_generate_var = "nossl"
	}
	
	if $atomia_clustered != 0{
			exec { "/bin/sed 's/%h/%{X-Forwarded-For}i/' -i /etc/apache2/conf.d/atomia-pa-apache.conf.ubuntu":
				unless => "/bin/grep 'X-Forwarded-For' /etc/apache2/conf.d/atomia-pa-apache.conf.ubuntu",
				require => Package["atomia-pa-apache"],
                notify => Exec["force-reload-apache"],
			}
	}
	
	$settings_content = generate("/etc/puppet/modules/apache_agent/files/settings.cfg.sh", $apache_agent_user, $apache_agent_password, $ssl_generate_var)
	file { "/usr/local/apache-agent/settings.cfg":
			owner   => root,
			group   => root,
			mode    => 440,
			content => $settings_content,
			require => Package["atomia-pa-apache"],
	}

	$statisticscopy_content = generate("/etc/puppet/modules/apache_agent/files/statisticscopy.conf.sh", $hostname)
	file { "/etc/statisticscopy.conf":
			owner   => root,
			group   => root,
			mode    => 440,
			content => $statisticscopy_content,
			require => Package["atomiastatisticscopy"],
	}

	file { "/var/log/httpd":
			owner   => root,
			group   => root,
			mode    => 600,
			ensure  => directory,
			before  => Service["apache2"],
	}
	
	file { "/var/www/cgi-wrappers":
		mode	=> 755,
	}
	
	# ensuring we have maps folder and needed files inside
	file { "/storage/configuration/maps":
			owner   => root,
			group   => www-data,
			mode    => 2750,
			ensure  => directory,
			require => Mount["/storage/configuration"],
	}
	
	file { "/storage/configuration/maps/frmrs.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/parks.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/phpvr.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/redrs.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/sspnd.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/users.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
	}
	
	file { "/storage/configuration/maps/vhost.map":
			owner   => root,
			group   => www-data,
			mode    => 440,
			ensure  => present,
			require => File["/storage/configuration/maps"],
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

	file { "/etc/apache2/conf.d/001-custom-errors":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/apache_agent/001-custom-errors",
			require => Package["apache2"],
			notify => Service["apache2"],
	}

        file { "/etc/apache2/suexec/www-data":
                owner   => root,
                group   => root,
                mode    => 444,
		source  => "puppet:///modules/apache_agent/suexec-conf",
                require => [ Package["apache2"], Package["apache2-suexec-custom-cgroups-atomia"] ],
                notify => Service["apache2"],
        }

	file { "/etc/cgconfig.conf" :
		owner => root,
		group => root,
		mode => 444,
		source => "puppet:///modules/apache_agent/cgconfig.conf",
		require => [ Package["cgroup-bin"] ],
	}

        service { atomia-pa-apache:
                name => apache-agent,
                enable => true,
                ensure => running,
                subscribe => [ Package["atomia-pa-apache"], File["/usr/local/apache-agent/settings.cfg"] ],
        }

	if !defined(Service['apache2']) {
	        service { apache2:
			name => apache2,
			enable => true,
			ensure => running,
	        }
	}

	if !defined(Exec['force-reload-apache']) {
	        exec { "force-reload-apache":
			refreshonly => true,
			before => Service["apache2"],
			command => "/etc/init.d/apache2 force-reload",
		}
	}

	if !defined(Exec['/usr/sbin/a2enmod rewrite']) {
	        exec { "/usr/sbin/a2enmod rewrite":
			unless => "/usr/bin/test -f /etc/apache2/mods-enabled/rewrite.load",
			require => Package["apache2"],
			notify => Exec["force-reload-apache"],
		}
        }

        exec { "/usr/sbin/a2enmod userdir":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/userdir.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }

        exec { "/usr/sbin/a2enmod fcgid":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/fcgid.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }

        exec { "/usr/sbin/a2enmod suexec":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/suexec.load",
                require => [ Package["apache2-suexec-custom-cgroups-atomia"], Package["apache2"] ],
                notify => Exec["force-reload-apache"],
        }

        exec { "/usr/sbin/a2enmod expires":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/expires.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }

        exec { "/usr/sbin/a2enmod headers":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/headers.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }

        exec { "/usr/sbin/a2enmod deflate":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/deflate.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }
		
        exec { "/usr/sbin/a2enmod include":
                unless => "/usr/bin/test -f /etc/apache2/mods-enabled/include.load",
                require => Package["apache2"],
                notify => Exec["force-reload-apache"],
        }
}

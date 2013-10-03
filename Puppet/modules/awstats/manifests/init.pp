class awstats (
	$awstats_agent_user,
	$awstats_agent_user_agent_password,
        $atomia_web_content_mount_point,
        $atomia_web_content_nfs_location,
        $atomia_web_config_mount_point,
        $atomia_web_config_nfs_location,
        $apache_conf_dir,
        $atomia_iis_config_nfs_location,
        $iis_config_dir,
	$ssl_enabled = 0

	) {
	if $atomia_linux_software_auto_update {
		package { atomia-pa-awstats: ensure => latest }
		package { atomiaprocesslogs: ensure => latest }
	} else {
		package { atomia-pa-awstats: ensure => present }
		package { atomiaprocesslogs: ensure => present }
	}
	package { awstats: ensure => installed }
	if !defined(Package['apache2-mpm-worker']) and !defined(Package['apache2-mpm-prefork']) and !defined(Package['apache2']) {
		package { apache2-mpm-worker: ensure => installed }
	}

	if $atomia_web_content_nfs_location {
		include nfsmount
	}

	if $ssl_enabled == 1 {
			$ssl_generate_var = "ssl"

			file { "/usr/local/awstats-agent/wildcard.key":
					owner   => root,
					group   => root,
					mode    => 440,
				   content => $ssl_cert_key,
					require => Package["atomia-pa-awstats"]
			}

			file { "/usr/local/awstats-agent/wildcard.crt":
					owner   => root,
					group   => root,
					mode    => 440,
					content => $ssl_cert_file,
					require => Package["atomia-pa-awstats"]
			}
	} else {
			$ssl_generate_var = "nossl"
	}

	$settings_content = generate("/etc/puppet/modules/awstats/files/settings.cfg.sh", $awstats_agent_user, $awstats_agent_user_agent_password, $ssl_generate_var)
	file { "/usr/local/awstats-agent/settings.cfg":
			owner   => root,
			group   => root,
			mode    => 440,
			content => $settings_content,
			require => Package["atomia-pa-awstats"]
	}

	service { awstats-agent:
			name => awstats-agent,
			enable => true,
			ensure => running,
			subscribe => [ Package["atomia-pa-awstats"], File["/usr/local/awstats-agent/settings.cfg"] ],
	}

	file { "/etc/cron.d/awstats":
		ensure => absent
	}

	file { "/etc/statisticsprocess.conf":
			owner   => root,
			group   => root,
			mode    => 400,
			source  => "puppet:///modules/awstats/statisticsprocess.conf",
	}

	file { "/etc/cron.d/convertlogs":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/awstats/convertlogs",
	}
	
	file { "/storage/content/logs/iis_logs/convert_logs.sh":
			owner   => root,
			group   => root,
			mode    => 544,
			source  => "puppet:///modules/awstats/convert_logs.sh",
	}

	file { "/etc/apache2/conf.d/awstats.conf":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/awstats/awstats.conf",
			notify	=> Service["apache2"],
	}
	
	file { "/etc/awstats/awstats.conf.local":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/awstats/awstats.conf.local",
	}
	
	file { "/storage/content/systemservices/public_html/nostats.html":
			owner   => root,
			group   => root,
			mode    => 444,
			source  => "puppet:///modules/awstats/nostats.html",
	}

	if !defined(File['/etc/apache2/sites-available/default']) {
	        file { "/etc/apache2/sites-available/default":
			ensure	=> absent,
		}
	}

	if !defined(File['/etc/apache2/sites-enabled/000-default']) {
	        file { "/etc/apache2/sites-enabled/000-default":
			ensure	=> absent,
		}
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
			require => Package["apache2-mpm-worker"],
			notify => Exec["force-reload-apache"],
		}
        }

}


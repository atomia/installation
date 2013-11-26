class daggre (
	$daggre_global_auth_token,
	$daggre_ip_addr, 
	$use_nfs3 = "", 
	$atomia_web_content_mount_point = "", 
	$atomia_web_content_nfs_location = "", 
	$atomia_web_config_mount_point = "", 
	$atomia_web_config_nfs_location = "", 
	$apache_conf_dir = "", 
	$atomia_iis_config_nfs_location = "",
	$iis_config_dir = "",
	$use_hiera = 0
	) {
	
	include mongodb

        # Keep for compatibility with non hiera deployments
        if $use_hiera == "0" {
                class { "nfsmount":
                        atomia_web_content_mount_point => $atomia_web_content_mount_point,
                        atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
                        atomia_web_config_mount_point => $atomia_web_config_mount_point,
                        atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
                        apache_conf_dir => $apache_conf_dir,
                        atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
                        iis_config_dir => $iis_config_dir,
                }
        }
	
	if $atomia_linux_software_auto_update {
		package { "daggre": 
			ensure => latest,
			require => Package["mongodb-10gen"]
		}
		package { "atomia-daggre-reporters-disk": 
			ensure => latest,
			require => Package["daggre"]
		}
		package { "atomia-daggre-reporters-weblog": 
			ensure => latest,
			require => Package["daggre"]
		}
	} else {
		package { "daggre": 
			ensure => present,
			require => Package["mongodb-10gen"]
		}
		package { "atomia-daggre-reporters-disk": 
			ensure => present,
			require => Package["daggre"]
		}
		package { "atomia-daggre-reporters-weblog": 
			ensure => present,
			require => Package["daggre"]
		}
	}
	
	$settings_content = generate("/etc/puppet/modules/daggre/files/settings.cfg.sh", $daggre_global_auth_token)
	file { "/etc/default/daggre":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $settings_content,
		require => Package["daggre"],		
	}
	
	$daggre_submit_content = generate("/etc/puppet/modules/daggre/files/daggre_submit.conf.sh", $daggre_global_auth_token, $daggre_ip_addr)
	file { "/etc/daggre_submit.conf":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $daggre_submit_content,
		require => Package["atomia-daggre-reporters-disk", "atomia-daggre-reporters-weblog"],		
	}	
	
	service { "daggre":
			name => daggre,
			enable => true,
			ensure => running,
			pattern => ".*/usr/bin/daggre.*",
			require => [ Package["daggre"], File["/etc/default/daggre"] ],
			subscribe => File["/etc/default/daggre"],
	}
				
}

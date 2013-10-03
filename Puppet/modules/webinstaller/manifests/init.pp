class webinstaller (
	$webinstaller_username,
	$webinstaller_password,
        $use_nfs3,
        $atomia_web_content_mount_point,
        $atomia_web_content_nfs_location,
        $atomia_web_config_mount_point,
        $atomia_web_config_nfs_location,
        $apache_conf_dir,
        $atomia_iis_config_nfs_location,
        $iis_config_dir
	) {
	if $atomia_linux_software_auto_update {
		package { atomiawebinstaller-api: ensure => latest }
		package { atomiawebinstaller-atomiachannel: ensure => latest }
		package { atomiawebinstaller-database: ensure => latest }
		package { atomiawebinstaller-masterserver: ensure => latest }
		if !defined(Package['atomiawebinstaller-client']) {
			package { atomiawebinstaller-client: ensure => latest }
		}
	} else {
		package { atomiawebinstaller-api: ensure => present }
		package { atomiawebinstaller-atomiachannel: ensure => present }
		package { atomiawebinstaller-database: ensure => present }
		package { atomiawebinstaller-masterserver: ensure => present }
		if !defined(Package['atomiawebinstaller-client']) {
			package { atomiawebinstaller-client: ensure => present }
		}
	}
        if $ssl_enabled {
                include apache_wildcard_ssl
        }

        class {
                'apache_password_protect':
                application_protect => "webinstaller"
        }

	include nfsmount
}


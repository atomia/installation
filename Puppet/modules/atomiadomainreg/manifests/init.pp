class atomiadomainreg ($domainreg_service_url,$domainreg_service_username,$domainreg_service_password, $atomia_domainreg_opensrs_user, $atomia_domainreg_opensrs_pass, $atomia_domainreg_opensrs_url, $atomia_domainreg_opensrs_tlds){
	if $atomia_linux_software_auto_update {
		package { atomiadomainregistration-masterserver: ensure => latest }
		package { atomiadomainregistration-client: ensure => latest }
	} else {
		package { atomiadomainregistration-masterserver: ensure => present }
		package { atomiadomainregistration-client: ensure => present }
	}

	if $ssl_enabled == '1' {
		include apache_wildcard_ssl
        }

	if $atomia_domainreg_opensrs_only {
		$domainreg_conf = generate("/etc/puppet/modules/atomiadomainreg/files/generate_conf.sh", $domainreg_service_username, $domainreg_service_password, $hostname, $domainreg_service_url, "nossl", $atomia_domainreg_opensrs_tlds, $atomia_domainreg_opensrs_user, $atomia_domainreg_opensrs_pass, $atomia_domainreg_opensrs_url)

		file { "/etc/domainreg.conf.puppet":
			owner   => root,
			group   => root,
			mode    => 444,
			content => $domainreg_conf,
			require => [ Package["atomiadomainregistration-masterserver"], Package["atomiadomainregistration-client"] ],
			notify => Exec["domainreg.conf puppetmerge"],
		}

		exec { "domainreg.conf puppetmerge":
			command => "/usr/bin/awk 'FILENAME == \"/etc/domainreg.conf\" && !/^db_/ { next } { print }' /etc/domainreg.conf /etc/domainreg.conf.puppet > /tmp/domainreg.conf.puppetmerge && mv /tmp/domainreg.conf.puppetmerge /etc/domainreg.conf",
			onlyif => "/usr/bin/test -f /etc/domainreg.conf && test -f /etc/domainreg.conf.puppet",
			refreshonly => true,
			notify => Service["atomiadomainregistration-api"],
		}

		service { atomiadomainregistration-api:
			name => atomiadomainregistration-api,
			enable => true,
			ensure => running,
			pattern => ".*/usr/bin/domainregistration.*",
			require => [ Package["atomiadomainregistration-masterserver"], Package["atomiadomainregistration-client"], File["/etc/domainreg.conf.puppet"] ],
		}
	}

	if defined(Class['apache_password_protect']) {
		class {
			'apache_password_protect':
				application_protect => "domainreg"
		}
	}

	service { apache2:
		name => apache2,
		enable => true,
		ensure => running,
	}

}


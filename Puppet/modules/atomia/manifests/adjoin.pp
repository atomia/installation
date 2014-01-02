class atomia::adjoin(
		$domain_name 			= "",
		$admin_user  			= "",
		$admin_password  		= "",
		$dc_ip  			= "",
		$base_dn 			= "", 
		$ldap_uris  			= "",  
		$bind_user 			= "", 
		$bind_password  		= "",
		$no_nscd 			= 0,
		$use_nslcd_conf			= 0
	) inherits adjoin::params {

	if $operatingsystem == 'windows' {

        exec { 'set-dns' :
            command => "\$wmi = Get-WmiObject win32_networkadapterconfiguration -filter \"ipenabled = 'true'\"; \$wmi.SetDNSServerSearchOrder(\"$dc_ip\") ",
            provider => powershell
            }
            
		exec { 'join-domain':
				command => "netdom join $hostname /Domain:$domain_name  /UserD:$admin_user /PasswordD:$admin_password /REBoot:5",
            	unless => "if((gwmi WIN32_ComputerSystem).Domain -ne \"$domain_name\") { exit 1 }",
            	provider => powershell
			}
	}
	else {
		package { libpam-ldap: ensure => present }

		file { "/etc/pam.d/common-account":
			ensure => file,
			owner	=> root,
			group	=> root,
			mode	=> 644,
			source	=> "puppet:///modules/atomia/adjoin/common-account",
		}

		$ldap_conf_content = generate("/etc/puppet/modules/atomia/files/adjoin/ldap.conf.sh", $base_dn, $ldap_uris, $bind_user, $bind_password)
		$nslcd_conf_content = generate("/etc/puppet/modules/atomia/files/adjoin/nslcd.conf.sh", $base_dn, $ldap_uris, $bind_user, $bind_password)
		if $no_nscd != 1 {
			package { nscd: ensure => present }
		
			file { "/etc/nscd.conf":
				ensure => file,
				owner	=> root,
				group	=> root,
				mode	=> 644,
				source	=> "puppet:///modules/atomia/adjoin/nscd.conf",
				require => Package["nscd"],
				notify => Service["nscd"],
			}
	               	service { nscd:
                        	enable => false,
                        	ensure => running,
                       	 	subscribe => File["/etc/nscd.conf"],
                	}

	                file { "/etc/nsswitch.conf":
	                        ensure => file,
        	                owner   => root,
                	        group   => root,
                       	 	mode    => 644,
                        	source  => "puppet:///modules/atomia/adjoin/nsswitch.conf",
                        	notify => Service["nscd"],
                	}
        	        file { "/etc/ldap.conf":
                	        ensure => file,
                        	owner   => root,
                        	group   => root,
                        	mode    => 644,
                        	content => $ldap_conf_content,
                        	notify => Service["nscd"],
                	}
		}
		else
		{
                	file { "/etc/nsswitch.conf":
                        	ensure => file,
                        	owner   => root,
                        	group   => root,
                        	mode    => 644,
                        	source  => "puppet:///modules/atomia/adjoin/nsswitch.conf",
                	}
                      file { "/etc/ldap.conf":
                                ensure => file,
                                owner   => root,
                                group   => root,
                                mode    => 644,
                                content => $ldap_conf_content,
                        }

		}

		if $use_nslcd_conf == 1 {
                      file { "/etc/nslcd.conf":
                                ensure => file,
                                owner   => root,
                                group   => root,
                                mode    => 600,
                                content => $nslcd_conf_content,
				notify => Service["nscd"],
                        }
		}

		file { "/etc/pam.d/common-auth":
			ensure => file,
			owner	=> root,
			group	=> root,
			mode	=> 644,
			source	=> "puppet:///modules/atomia/adjoin/common-auth",
		}

		file { "/etc/pam.d/common-session":
			ensure => file,
			owner	=> root,
			group	=> root,
			mode	=> 644,
			source	=> "puppet:///modules/atomia/adjoin/common-session",
		}

	}
}


class atomiadns (

		$atomia_dns_ns_group = $atomiadns::params::atomia_dns_ns_group,
		$ssl_enabled = $atomiadns::params::ssl_enabled,
		$ssl_cert_key = $atomiadns::params::ssl_cert_key,
		$ssl_cert_file = $atomiadns::params::ssl_cert_file,
		$atomia_dns_agent_user = $atomiadns::params::atomia_dns_agent_user, 
		$atomia_dns_agent_password = $atomiadns::params::atomia_dns_agent_password,  
		$atomia_dns_url = $atomiadns::params::atomia_dns_url,  
		$nameserver1 =   $atomiadns::params::nameserver1,
		$nameservers =  $atomiadns::params::nameservers,
		$registry =  $atomiadns::params::registry,
		$atomia_dns_zones_to_add = $atomiadns::params::atomia_dns_zones_to_add

	) inherits atomiadns::params {

	package { 
		atomiadns-masterserver: ensure => present 
	}

	if !defined(Package['atomiadns-client']) {
		package { 
			atomiadns-client: ensure => latest 
		}
	}


	if $ssl_enabled == '1' {
		include apache_wildcard_ssl
    	}

	if !defined(Class['apache_password_protect']) {
	        class { 'apache_password_protect':
                	application_protect => "atomiadns"
		}
	}

	if $atomia_dns_ns_group {
		exec 
		{ 
			add_nameserver_group:
				require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
				unless => "/usr/bin/sudo -u postgres psql zonedata -tA -c \"SELECT name FROM nameserver_group WHERE name = '$atomia_dns_ns_group'\" | grep '^$atomia_dns_ns_group\$'",
				command => "/usr/bin/sudo -u postgres psql zonedata -c \"INSERT INTO nameserver_group (name) VALUES ('$atomia_dns_ns_group')\"",
		}
	}
	
	if $ssl_enabled {
		file { "/etc/atomiadns-mastercert.pem":
				owner   => root,
				group   => root,
				mode    => 440,
				content => $ssl_cert_file,
		}

		$atomiadns_conf = generate("/etc/puppet/modules/atomiadns/files/generate_conf.sh", $atomia_dns_agent_user, $atomia_dns_agent_password, $hostname, $atomia_dns_url, "ssl")

	} 
	else {
			$atomiadns_conf = generate("/etc/puppet/modules/atomiadns/files/generate_conf.sh", $atomia_dns_agent_user, $atomia_dns_agent_password, $hostname, $atomia_dns_url, "nossl")
	}

    file { "/etc/atomiadns.conf.master":
            owner   => root,
            group   => root,
            mode    => 444,
            content => $atomiadns_conf,
            require => Package["atomiadns-masterserver"],
    }
	
	file { "/usr/bin/atomiadns_config_sync":
            owner   => root,
            group   => root,
            mode    => 500,
			source  => "puppet:///modules/atomiadns/atomiadns_config_sync",
            require => [ Package["atomiadns-masterserver"] ],
    }
	
	exec { "atomiadns_config_sync":
            refreshonly => true,
			require => [ File["/usr/bin/atomiadns_config_sync"], File["/etc/atomiadns.conf.master"] ],
			command => "/usr/bin/atomiadns_config_sync $atomia_dns_ns_group",
    }


	if $atomia_dns_zones_to_add {
		file { "/usr/share/doc/atomiadns-masterserver/zones_to_add.txt":
			owner   => root,
			group   => root,
			mode    => 500,
			content	=> $atomia_dns_zones_to_add,
			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
			notify  => Exec['remove_lock_file'],
		}

		exec { "remove_lock_file":
			command => "/bin/rm -f /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt",
			refreshonly => true,
		}

		file { "/usr/share/doc/atomiadns-masterserver/add_zones.sh":
			owner   => root,
			group   => root,
			mode    => 500,
			source	=> "puppet:///modules/atomiadns/add_zones.sh",
			require => [ Package["atomiadns-masterserver"], Package["atomiadns-client"] ],
		}

    	exec { "atomiadns_add_zones":
			require => [ File["/usr/share/doc/atomiadns-masterserver/zones_to_add.txt"]],
			command => "/bin/sh /usr/share/doc/atomiadns-masterserver/add_zones.sh $atomia_dns_ns_group $nameserver1 $nameservers $registry",
			unless => "/usr/bin/test -f /usr/share/doc/atomiadns-masterserver/sync_zones_done.txt",
		}
	}
}


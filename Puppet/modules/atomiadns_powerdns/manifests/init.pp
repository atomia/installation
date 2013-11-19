class atomiadns_powerdns ($ssl_enabled,$ssl_cert_file,$atomia_dns_agent_user,$atomia_dns_agent_password,$atomia_dns_url,$atomia_dns_ns_group)
{
	if $atomia_linux_all_in_one {
		require atomiadns
	}

	if $atomia_linux_software_auto_update {
		package { atomiadns-powerdns-database: ensure => latest }
		package { atomiadns-powerdnssync: ensure => latest }
	} else {
		package { atomiadns-powerdns-database: ensure => present }
		package { atomiadns-powerdnssync: ensure => present }
	}

	package { pdns-static: ensure => present, require => [ Service["atomiadns-powerdnssync"] ] }

        service { atomiadns-powerdnssync:
                name => atomiadns-powerdnssync,
                enable => true,
                ensure => running,
		pattern => ".*powerdnssync.*",
		require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"], File["/etc/atomiadns.conf.powerdnssync"] ],
		subscribe => [ File["/etc/atomiadns.conf.powerdnssync"] ],
        }

	if $ssl_enabled == '1' {
                file { "/etc/atomiadns-mastercert.pem":
                        owner   => root,
                        group   => root,
                        mode    => 440,
                        content => $ssl_cert_file,
                }

		$atomiadns_conf = generate("/etc/puppet/modules/atomiadns_powerdns/files/generate_conf.sh", $atomia_dns_agent_user, $atomia_dns_agent_password, $hostname, $atomia_dns_url, "ssl")
	} else {
		$atomiadns_conf = generate("/etc/puppet/modules/atomiadns_powerdns/files/generate_conf.sh", $atomia_dns_agent_user, $atomia_dns_agent_password, $hostname, $atomia_dns_url, "nossl")
	}

        file { "/etc/atomiadns.conf.powerdnssync":
                owner   => root,
                group   => root,
                mode    => 444,
                content => $atomiadns_conf,
                require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"] ],
		notify => Exec["atomiadns_config_sync"],
        }
	if !defined(File["/usr/bin/atomiadns_config_sync"])
	{
        	file { "/usr/bin/atomiadns_config_sync":
                	owner   => root,
                	group   => root,
                	mode    => 500,
			source  => "puppet:///modules/atomiadns_powerdns/atomiadns_config_sync",
                	require => [ Package["atomiadns-powerdns-database"], Package["atomiadns-powerdnssync"] ],
        	}
	        exec { "atomiadns_config_sync":
	                refreshonly => true,
        	        require => File["/usr/bin/atomiadns_config_sync"],
               	 	before => Service["atomiadns-powerdnssync"],
                	command => "/usr/bin/atomiadns_config_sync $atomia_dns_ns_group",
        	}

	}

}


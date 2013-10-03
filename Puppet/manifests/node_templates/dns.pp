# AtomiaDNS Master server
node 'atomia.com' inherits 'linux_base' {

	class { 'atomiadns' :

		atomia_dns_ns_group => $atomia_dns_ns_group,
		ssl_enabled => $ssl_enabled,
		ssl_cert_key => $ssl_cert_key,
		ssl_cert_file => $ssl_cert_file,
		atomia_dns_agent_user => $atomia_dns_agent_user, 
		atomia_dns_agent_password => $atomia_dns_agent_password,  
		atomia_dns_url => $atomia_dns_url,  
		atomia_dns_zones_to_add => $atomia_dns_zones_to_add,
		nameserver1 =>   $nameserver1,
		nameservers =>  $nameservers,
		registry =>  $registry,

	}
}

# PowerDNS nodes
node 'atomia.com' inherits 'linux_base'  {

	class { 'atomiadns_powerdns' :

		atomia_dns_ns_group => $atomia_dns_ns_group,
		ssl_enabled => $ssl_enabled,
                ssl_cert_file => $ssl_cert_file,
                atomia_dns_agent_user => $atomia_dns_agent_user,
                atomia_dns_agent_password => $atomia_dns_agent_password,
                atomia_dns_url => $atomia_dns_url,
	}

}

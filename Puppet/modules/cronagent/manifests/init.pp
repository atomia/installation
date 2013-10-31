class cronagent (

	$cronagent_global_auth_token = $cronagent::params::atomia_dns_ns_group, 
	$cronagent_min_part = $cronagent::params::cronagent_min_part,  
	$cronagent_max_part = $cronagent::params::cronagent_max_part, 
	$cronagent_mail_host = $cronagent::params::cronagent_mail_host, 
	$cronagent_mail_port = $cronagent::params::cronagent_mail_port, 
	$cronagent_mail_ssl = $cronagent::params::cronagent_mail_ssl, 
	$cronagent_mail_from = $cronagent::params::cronagent_mail_from, 
	$cronagent_mail_user = $cronagent::params::cronagent_mail_user, 
	$cronagent_mail_pass = $cronagent::params::cronagent_mail_pass

) inherits cronagent::params {
	
	include mongodb
	
	package { "atomia-cronagent": 
		ensure => present,
		require => Package["mongodb-10gen"]
	}
	
	package { "postfix" :
		ensure => present,
	}

	
	$settings_content = generate("/etc/puppet/modules/cronagent/files/settings.cfg.sh", $cronagent_global_auth_token, $cronagent_min_part, $cronagent_max_part, $cronagent_mail_host, $cronagent_mail_port, $cronagent_mail_ssl, $cronagent_mail_from, "$cronagent_mail_user", "$cronagent_mail_pass")
	file { "/etc/default/cronagent":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $settings_content,
		require => Package["atomia-cronagent"],		
	}
	
	service { "atomia-cronagent":
			name => atomia-cronagent,
			enable => true,
			ensure => running,
			pattern => ".*/usr/bin/cronagent.*",
			require => [ Package["atomia-cronagent"], File["/etc/default/cronagent"] ],
			subscribe => File["/etc/default/cronagent"],
	}
				
}

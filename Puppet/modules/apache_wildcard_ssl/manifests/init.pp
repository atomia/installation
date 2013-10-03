class apache_wildcard_ssl {	        
	file { "/etc/apache2/wildcard.key":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $ssl_cert_key,
		require => File["/etc/apache2"],
	}

	file { "/etc/apache2/wildcard.crt":
		owner   => root,
		group   => root,
		mode    => 440,
		content => $ssl_cert_file,
		require => File["/etc/apache2"],
	}

	file { "/etc/apache2/sites-enabled":
		owner   => root,
		group   => root,
		mode    => 755,
		ensure	=> directory,
		require => File["/etc/apache2"],
	}

	file { "/etc/apache2/sites-enabled/001-ssl":
		owner   => root,
		group   => root,
		mode    => 440,
		source  => "puppet:///modules/apache_wildcard_ssl/001-ssl",
		require => File["/etc/apache2/sites-enabled"],
	}

	exec { "/usr/sbin/a2enmod ssl":
		unless => "/usr/bin/test -f /etc/apache2/mods-enabled/ssl.load",
		onlyif => "/usr/bin/test -f /usr/sbin/a2enmod",
		notify => Exec["force-reload-apache-wildcard-ssl"],
	}

        exec { "force-reload-apache-wildcard-ssl":
                refreshonly => true,
                command => "/etc/init.d/apache2 force-reload",
        }
}

node 'linux_base' {
	
	include 'atomiarepository'

	ssh_authorized_key { "info@atomia.com":
    		ensure      => present,
    		type        => 'ssh-rsa',
    		key         => $atomia_public_key,
   	 	user        => $atomia_public_key_user,
	}

	# Packages
	package { "vim" :
		ensure => latest
	}	
	
	package { "curl" :
		ensure => latest
	}
}

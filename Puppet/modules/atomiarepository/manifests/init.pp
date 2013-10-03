class atomiarepository {
	file { "/etc/apt/sources.list.d/atomia.list":
		owner   => root,
		group   => root,
		mode    => 440,
		content => "deb http://apt.atomia.com/ubuntu-$lsbdistcodename $lsbdistcodename main"
	}

	file { "/etc/apt/ATOMIA-GPG-KEY.pub":
		owner   => root,
		group   => root,
		mode    => 440,
		source  => "puppet:///modules/atomiarepository/ATOMIA-GPG-KEY.pub"
	}

	exec { "add keys":
		command => "/usr/bin/apt-key add /etc/apt/ATOMIA-GPG-KEY.pub",
		onlyif => ["/usr/bin/test -f /etc/apt/ATOMIA-GPG-KEY.pub"],
		subscribe => File["/etc/apt/ATOMIA-GPG-KEY.pub"],
		refreshonly => true
	}

	file { "/etc/apt/apt.conf.d/80atomiaupdate":
		owner   => root,
		group   => root,
		mode    => 440,
		source  => "puppet:///modules/atomiarepository/80atomiaupdate"
	}
}

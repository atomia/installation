node 'atomia.com' inherits 'linux_base' {

        class { 'atomia_mysql' :
		mysql_username => $mysql_username,
		mysql_password => $mysql_password,
		provisioning_host => $provisioning_host
        }
}

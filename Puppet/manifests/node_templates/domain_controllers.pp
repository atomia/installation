#master
node 'atomia.com' {
        class { 'domain_controller':
                domain_name => $ad_domain,
                netbios_name => $ad_shortname,
                dc_ip => $dc_ip,
                domain_password => $dc_restore_password,
                is_master => false,
                admin_user => $admin_user,
                admin_password => $admin_user_password
        }
}

#slaves
node 'atomia.com' {
	class { 'domain_controller':
		domain_name => $ad_domain,
		netbios_name => $ad_shortname,
		dc_ip => $dc_ip,
		domain_password => $dc_restore_password,
		is_master => false,
		admin_user => $admin_user,
		admin_password => $admin_user_password	
	}
}



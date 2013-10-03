node 'atomia.com' {


        class { 'adjoin':
                domain_name => $ad_domain,
                admin_user => $admin_user,
                admin_password => $admin_user_password,
                dc_ip => $dc_ip
        }	


	class { 'iis' :

	}

} 

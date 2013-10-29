node 'atomia.com' inherits 'linux_base' {

	class { 'adjoin' :
		base_dn => $base_dn, 
		ldap_uris => $ldap_uris, 
		bind_user => $bind_user, 
		bind_password => $bind_password,
		no_nscd => 1
	} 

	class { 'fsagent' :
		fs_agent_user => $fs_agent_user,	
		fs_agent_password => $fs_agent_password,
                atomia_web_content_mount_point => $atomia_web_content_mount_point,
                atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
                atomia_web_config_mount_point => $atomia_web_config_mount_point,
                atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
                apache_conf_dir => $apache_conf_dir,
                atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
                iis_config_dir => $iis_config_dir
	}


}

node 'atomia.com' inherits 'linux_base' {

	class { 'daggre' :

        	daggre_global_auth_token => $daggre_global_auth_token,
        	daggre_ip_addr => $daggre_ip_addr,
        	use_nfs3 => $use_nfs3,
        	atomia_web_content_mount_point => $atomia_web_content_mount_point,
        	atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
        	atomia_web_config_mount_point => $atomia_web_config_mount_point,
        	atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
        	apache_conf_dir => $apache_conf_dir,
        	atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
        	iis_config_dir => $iis_config_dir

	}

}

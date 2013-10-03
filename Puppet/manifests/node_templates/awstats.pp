node 'atomia.com' inherits 'linux_base' {

	class { 'awstats' :
		awstats_agent_user => $awstats_agent_user,
		awstats_agent_user_agent_password => $awstats_agent_user_agent_password,
        	atomia_web_content_mount_point => $atomia_web_content_mount_point,
        	atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
        	atomia_web_config_mount_point => $atomia_web_config_mount_point,
        	atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
        	apache_conf_dir => $apache_conf_dir,
        	atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
        	iis_config_dir => $iis_config_dir

	}

}

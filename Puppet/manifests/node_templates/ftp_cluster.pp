#FTP MASTER
node 'atomia.com' inherits 'linux_base' {


        class { 'adjoin' :
                base_dn => $base_dn,
                ldap_uris => $ldap_uris,
                bind_user => $bind_user,
                bind_password => $bind_password
        }

	class { 'pureftpd' :
        	pureftpd_agent_user => $pureftpd_agent_user,
        	pureftpd_agent_password => $pureftpd_agent_password,
        	pureftpd_master_ip => $pureftpd_master_ip,
        	provisioning_host => $provisioning_host,
        	pureftpd_password => $pureftpd_password,
        	use_nfs3 => $use_nfs3,
        	atomia_web_content_mount_point => $atomia_web_content_mount_point,
        	atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
        	atomia_web_config_mount_point => $atomia_web_config_mount_point,
        	atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
        	apache_conf_dir => $apache_conf_dir,
        	atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
        	iis_config_dir => $iis_config_dir,
		pureftpd_slave_password => $pureftpd_slave_password,
		atomia_pureftp_db_is_master => 1,
		ftp_cluster_ip => $ftp_cluster_ip

	}

}

node 'atomia.com' inherits 'linux_base' {


        class { 'adjoin' :
                base_dn => $base_dn,
                ldap_uris => $ldap_uris,
                bind_user => $bind_user,
                bind_password => $bind_password
        }

        class { 'pureftpd' :
                pureftpd_agent_user => $pureftpd_agent_user,
                pureftpd_agent_password => $pureftpd_agent_password,
                pureftpd_master_ip => $pureftpd_master_ip,
                provisioning_host => $provisioning_host,
                pureftpd_password => $pureftpd_password,
                use_nfs3 => $use_nfs3,
                atomia_web_content_mount_point => $atomia_web_content_mount_point,
                atomia_web_content_nfs_location => $atomia_web_content_nfs_location,
                atomia_web_config_mount_point => $atomia_web_config_mount_point,
                atomia_web_config_nfs_location => $atomia_web_config_nfs_location,
                apache_conf_dir => $apache_conf_dir,
                atomia_iis_config_nfs_location => $atomia_iis_config_nfs_location,
                iis_config_dir => $iis_config_dir,
		pureftpd_slave_password => $pureftpd_slave_password,
                atomia_pureftp_db_is_master => 0,
		ftp_cluster_ip => $ftp_cluster_ip

        }

}

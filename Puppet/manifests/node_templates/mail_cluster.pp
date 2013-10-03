#Master
node 'atomia.com' inherits 'linux_base' {


        class { 'adjoin' :
                base_dn => $base_dn,
                ldap_uris => $ldap_uris,
                bind_user => $bind_user,
                bind_password => $bind_password
        }


	class { 'postfix_mx' : 
                provisioning_host => $provisioning_host,
                atomia_mail_db_is_master => 1,
                atomia_mail_storage_nfs_location => $atomia_mail_storage_nfs_location,
                atomia_mail_master_ip => $atomia_mail_master_ip,
                atomia_mail_agent_password => $atomia_mail_agent_password,
		mail_slave_password => $mail_slave_password,
		mail_server_id => 1
	}        
}

#Replica
node 'atomia.com' inherits 'linux_base' {


        class { 'adjoin' :
                base_dn => $base_dn,
                ldap_uris => $ldap_uris,
                bind_user => $bind_user,
                bind_password => $bind_password
        }


	class { 'postfix_mx' : 
                provisioning_host => $provisioning_host,
                atomia_mail_db_is_master => 0,
                atomia_mail_storage_nfs_location => $atomia_mail_storage_nfs_location,
                atomia_mail_master_ip => $atomia_mail_master_ip,
                atomia_mail_agent_password => $atomia_mail_agent_password,
		mail_slave_password => $mail_slave_password,
		mail_server_id => 2
	}        
}







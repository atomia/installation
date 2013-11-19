node 'windows_base' {
	
	class { 'adjoin':
		domain_name => $ad_domain,
		admin_user => $admin_user,
		admin_password => $admin_user_password,	
		dc_ip => $dc_ip
	}	

	class { 'atomia_windows_base' :

        	app_password                                   => $app_password, 
        	ad_domain                                      => $ad_shortname, 
        	database_server                                => $database_server,
		mirror_database_server			       => $mirror_database_server,
        	appdomain                                      => $appdomain,
        	actiontrail                                    => $actiontrail,
        	login                                          => $login,
        	order                                          => $order,
        	billing                                        => $billing,
        	admin                                          => $admin,
       		hcp                                            => $hcp,
        	automationserver                               => $automationserver,
        	automationserver_encryption_cert_thumb         => $automationserver_encryption_cert_thumb,
        	billing_encryption_cert_thumb                  => $billing_encryption_cert_thumb,
        	root_cert_thumb                                => $root_cert_thumb,
        	signing_cert_thumb                             => $signing_cert_thumb,
        	billing_plugin_config                          => $billing_plugin_config,
        	send_invoice_email_subject_format              => $send_invoice_email_subject_format,
        	domainreg_service_url                          => $domainreg_service_url,
        	domainreg_service_username                     => $domainreg_service_username,
        	domainreg_service_password                     => $domainreg_service_password,
        	actiontrail_ip                                 => $actiontrail_ip,
        	mail_sender_address                            => $mail_sender_address,
        	mail_server_host                               => $mail_server_host,
        	mail_server_port                               => $mail_server_port,
        	mail_server_username                           => $mail_server_username,
        	mail_server_password                           => $mail_server_password,
        	mail_server_use_ssl                            => $mail_server_use_ssl,
        	mail_bcc_list                                  => $mail_bcc_list,
        	mail_reply_to                                  => $mail_reply_to,
        	storage_server_hostname                        => $storage_server_hostname,
        	mail_dispatcher_interval                       => $mail_dispatcher_interval

	}
}

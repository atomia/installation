node 'atomia.com' inherits 'linux_base' {

	class { 'cronagent' :

	        cronagent_global_auth_token => $cronagent_global_auth_token,
        	cronagent_min_part => $cronagent_min_part,
        	cronagent_max_part => $cronagent_max_part,
        	cronagent_mail_host => $cronagent_mail_host,
        	cronagent_mail_port => $cronagent_mail_port,
        	cronagent_mail_ssl => $cronagent_mail_ssl,
        	cronagent_mail_from => $cronagent_mail_from,
        	cronagent_mail_user => $cronagent_mail_user,
        	cronagent_mail_pass => $cronagent_mail_pass,

	}
	 
}

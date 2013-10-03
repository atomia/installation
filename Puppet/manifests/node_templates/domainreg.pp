node 'atomia.com' inherits 'linux_base' {

        class { 'atomiadomainreg' :

		domainreg_service_url => $domainreg_service_url,
		domainreg_service_username => $domainreg_service_username,
		domainreg_service_password => $domainreg_service_password,
		atomia_domainreg_opensrs_user => $atomia_domainreg_opensrs_user,
		atomia_domainreg_opensrs_pass => $atomia_domainreg_opensrs_pass,
		atomia_domainreg_opensrs_url => $atomia_domainreg_opensrs_url,
		atomia_domainreg_opensrs_tlds => $atomia_domainreg_opensrs_tlds

        }

}

class iis {

        dism { 'NetFx3':
                ensure => present
        }

        #Install IIS and modules
        dism { 'IIS-WebServerRole':
                ensure => present
        }

        dism { 'IIS-ISAPIFilter':
                ensure => present
        }

        dism { 'IIS-ISAPIExtensions':
                ensure => present
        }

        dism { 'IIS-NetFxExtensibility':
                ensure => present
        }
        dism { 'IIS-ASPNET':
                ensure => present
        }

        dism { 'IIS-CommonHttpFeatures':
                ensure => present
        }
	
	dism { 'IIS-ASPNET45' :
		ensure => present
	}

        dism { 'IIS-StaticContent':
                ensure => present
        }

        dism { 'IIS-DefaultDocument':
                ensure => present
        }

        dism { 'IIS-ManagementConsole':
                ensure => present
        }

        dism { 'IIS-ManagementService':
                ensure => present
        }

        dism { 'IIS-HttpRedirect':
                ensure => present
        }
	
	dism { 'NETFx4Extended-ASPNET45':
		ensure => present
	}

	dism { 'IIS-NetFxExtensibility45':
		ensure => present
	}

}

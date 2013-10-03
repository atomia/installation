class atomia_resource_transformations {

        file { 'Domainreg' :
		path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.Domainreg.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.Domainreg.erb') 
        }

        file { 'AtomiaDNS' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.Atomiadns.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.Atomiadns.erb')
        }
        
	file { 'ActiveDirectory' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.ActiveDirectory.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.ActiveDirectory.erb')
        }
	
	file { 'CronAgent' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.CronAgent.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.CronAgent.erb')
	}

        file { 'MySQL' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.MySQL.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.MySQL.erb')
        }	 	

        file { 'EC2' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.EC2.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.EC2.erb')
        }	 	

        file { 'Daggre' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.Daggre.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.Daggre.erb')
        }	 	

        file { 'Awstats' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.Awstats.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.Awstats.erb')
        }	 	

        file { 'FSAgent' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.FSAgent.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.FSAgent.erb')
        }	 	

        file { 'Webinstaller' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.Webinstaller.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.Webinstaller.erb')
        }	 	

        file { 'PureFTPD' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.PureFTPD.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.PureFTPD.erb')
        }	 	

        file { 'ApacheAgent' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.ApacheAgent.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.ApacheAgent.erb')
        }	 	

        file { 'PostfixAndDovecot' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.PostfixAndDovecot.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.PostfixAndDovecot.erb')
        }
	 	
        file { 'IISCluster' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.IIS.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.IIS.erb')
        }
        
	file { 'MSSQL' :
                path    => "C:\Program Files (x86)\Atomia\AutomationServer\Common\Transformation Files\Resources.MSSQL.xml",
                ensure => 'file',
                content  => template('atomia_resource_transformations/Resources.MSSQL.erb')
       } 
}


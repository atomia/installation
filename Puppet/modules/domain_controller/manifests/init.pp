# modules/domain_controller/init.pp
# Puppet Domain Controller Module
# Author: Stefan Mortensen <stefan.mortensen@atomia.com> - Atomia AB 2013
#
# Dependencies:
#   Dism module by Puppet Labs https://forge.puppetlabs.com/puppetlabs/dism v0.1.0+
#   Powershell module by joshcooper https://forge.puppetlabs.com/joshcooper/powershell v0.0.5+

class domain_controller (
        
        $domain_name = $domain_controller::params::domain_name,
        $netbios_name = $domain_controller::params::netbios_name,
        $domain_password = $domain_controller::params::domain_password,
        $dc_ip = $domain_controller::params::dc_ip,
        $is_master = $domain_controller::params::is_master,
        $admin_user = $domain_controller::params::admin_user,
        $admin_password = $domain_controller::params::admin_password

) inherits domain_controller::params {

        dism { 'NetFx3':
                ensure => present
        }

        dism { 'DirectoryServices-DomainController':
                 ensure => present
        }

        # Create a new domain
        if $is_master == 'true' {

              file { "newforest_unattended.txt":
                        path    => "c:/install/newforest_unattended.txt",
                        ensure => file,
                        content => template('domain_controller/new_forest.erb'),
                }

                exec { 'new-domain' :
                        command => 'DCPROMO /unattend:C:\install\newforest_unattended.txt',
                        unless => 'if (((gwmi WIN32_ComputerSystem).Domain) -eq "$domain_name") { exit 1 }',
                        provider => powershell,
                }
        }
        else {

            # Set dns server to domain controller
            exec { 'set-dns' :
                command => "\$wmi = Get-WmiObject win32_networkadapterconfiguration -filter \"ipenabled = 'true'\"; \$wmi.SetDNSServerSearchOrder(\"$dc_ip\") ",
                provider => powershell
                }

            exec { 'existing-domain' : 
                command => "dcpromo /unattend /InstallDns:yes /confirmGC:yes /replicaOrNewDomain:replica /replicaDomainDNSName:$domain_name /safeModeAdminPassword:$domain_password /rebootOnCompletion:yes /UserName:$admin_user /Password:$admin_password /UserDomain:$netbios_name",
                unless => "if((gwmi WIN32_ComputerSystem).Domain -ne \"$domain_name\") { exit 1 }",
                provider => powershell
            }

        }

}


# modules/atomia_windows_base/init.pp
# Windows base module
# Author: Stefan Mortensen <stefan.mortensen@atomia.com> - Atomia AB 2013
#
# Dependencies:
#   Dism module by Puppet Labs https://forge.puppetlabs.com/puppetlabs/dism v0.1.0+
#   Powershell module by joshcooper https://forge.puppetlabs.com/joshcooper/powershell v0.0.5+

class atomia_windows_base(

        $app_password = $atomia_windows_base::params::app_password,
        $ad_domain = $atomia_windows_base::params::ad_domain,
        $database_server = $atomia_windows_base::params::database_server,
        $appdomain = $atomia_windows_base::params::appdomain,
        $actiontrail = $atomia_windows_base::params::actiontrail,
        $login = $atomia_windows_base::params::login,
        $order = $atomia_windows_base::params::order,
        $billing = $atomia_windows_base::params::billing,
        $admin = $atomia_windows_base::params::admin,
        $hcp = $atomia_windows_base::params::hcp,
        $automationserver = $atomia_windows_base::params::automationserver,
        $automationserver_encryption_cert_thumb = $atomia_windows_base::params::automationserver_encryption_cert_thumb,
        $billing_encryption_cert_thumb = $atomia_windows_base::params::billing_encryption_cert_thumb,
        $billing_plugin_config = $atomia_windows_base::params::billing_plugin_config,
        $send_invoice_email_subject_format = $atomia_windows_base::params::send_invoice_email_subject_format,
        $domainreg_service_url = $atomia_windows_base::params::domainreg_service_url,
        $domainreg_service_username = $atomia_windows_base::params::domainreg_service_username,
        $domainreg_service_password = $atomia_windows_base::params::domainreg_service_password,
        $actiontrail_ip = $atomia_windows_base::params::actiontrail_ip,
        $root_cert_thumb = $atomia_windows_base::params::root_cert_thumb,
        $signing_cert_thumb = $atomia_windows_base::params::signing_cert_thumb,
        $mail_sender_address = $atomia_windows_base::params::mail_sender_address,
        $mail_server_host = $atomia_windows_base::params::mail_server_host,
        $mail_server_port = $atomia_windows_base::params::mail_server_port,
        $mail_server_username = $atomia_windows_base::params::mail_server_username,
        $mail_server_password = $atomia_windows_base::params::mail_server_password,
        $mail_server_use_ssl = $atomia_windows_base::params::mail_server_use_ssl,
        $mail_bcc_list = $atomia_windows_base::params::mail_bcc_list,
        $mail_reply_to = $atomia_windows_base::params::mail_reply_to,
        $storage_server_hostname = $atomia_windows_base::params::storage_server_hostname,
        $mail_dispatcher_interval = $atomia_windows_base::params::mail_dispatcher_interval     

        ) inherits atomia_windows_base::params {

        dism { 'NetFx3':
                ensure => present
        }

        dism { MSMQ-Server:
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
        # End IIS and modules

        file { 'c:/install' :
                ensure => 'directory'
        }

        file { 'c:/install/base.ps1' :
                ensure => 'file',
                source  => "puppet:///modules/atomia_windows_base/baseinstall.ps"
        }

        file { 'c:/install/disableweakssl.reg' :
                ensure => 'file',
                source  => "puppet:///modules/atomia_windows_base/disableweakssl.reg"
        }

        file { 'c:/install/Windows6.1-KB2554746-x64.msu' :
                ensure => 'file',
                source => "puppet:///modules/atomia_windows_base/Windows6.1-KB2554746-x64.msu"

        }

        exec { 'base-install':
                command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\base.ps1',
                creates => 'C:\install\installed'
        }


        file { 'C:\Program Files (x86)\Atomia' :
                ensure => 'directory'
        }

        file { 'C:\Program Files (x86)\Atomia\Common' :
                ensure => 'directory'
        }

        file { "unattended.ini":
                path    => "C:\Program Files (x86)\Atomia\Common\unattended.ini",
                ensure => file,
                content => template('atomia_windows_base/ini_template.erb'),
        }

        file { "C:\Program Files (x86)\Atomia\Common\atomia.ini.location":
                content => "C:\Program Files (x86)\Atomia\Common",
        }

        file { 'C:\ProgramData\Atomia Installer\appupdater.ini' :
                ensure => 'file',
                source  => "puppet:///modules/atomia_windows_base/appupdater.ini"
        }     
	
	file { 'C:\install\recreate_all_config_files.ps1' :
              	ensure => 'file',
                source  => "puppet:///modules/atomia_windows_base/recreate_all_config_files.ps1"
        }

        file { 'C:\install\installcert.ps1' :
                ensure => 'file',
                source  => "puppet:///modules/atomia_windows_base/installcert.ps1"
        }

        file { 'c:/install/certificates' :
                source => 'puppet:///modules/atomia_windows_base/tools/certificates',
                recurse => true
        }


}

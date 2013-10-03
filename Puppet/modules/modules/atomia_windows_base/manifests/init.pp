# modules/atomia_windows_base/init.pp
# Windows base module
# Author: Stefan Mortensen <stefan.mortensen@atomia.com> - Atomia AB 2013
#
# Dependencies:
#   Dism module by Puppet Labs https://forge.puppetlabs.com/puppetlabs/dism v0.1.0+
#   Powershell module by joshcooper https://forge.puppetlabs.com/joshcooper/powershell v0.0.5+

class atomia_windows_base {

        dism { 'NetFx3':
                ensure => present
        }
        dism { MSMQ-Server:
                ensure => present
        }

        file { 'c:/install' :
                ensure => 'directory'
        }

        file { 'c:/install/base.ps1' :
                ensure => 'file',
                source  => "puppet:///modules/windows_base/baseinstall.ps"
        }

#        file { 'c:/install/install_sql_express.ps1' :
#                ensure => 'file',
#                source  => "puppet:///modules/windows_base/install_sql_express.ps1"
#        }

        file { 'c:/install/disableweakssl.reg' :
                ensure => 'file',
                source  => "puppet:///modules/windows_base/disableweakssl.reg"
        }

        file { 'c:/install/Windows6.1-KB2554746-x64.msu' :
                ensure => 'file',
                source => "puppet:///modules/windows_base/Windows6.1-KB2554746-x64.msu"

        }

        exec { 'base-install':
                command => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned -file C:\install\base.ps1',
                creates => 'C:\install\installed'
        }


#        file { 'c:/install/certificates' :
#                source => 'puppet:///modules/windows_base/CA/certificates',
#                recurse => true
#        }


}

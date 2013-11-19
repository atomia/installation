import 'variables.pp'
import 'nodes/*.pp'

node default {
	include atomia_facts

	if $is_puppetmaster {
		package { apache2-utils:
			ensure => present
		}
	}
}

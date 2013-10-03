node 'atomia.com' inherits 'linux_base' {

	class { 'atomia_pa_haproxy' :
		atomia_pa_haproxy_user => $atomia_pa_haproxy_user,
		atomia_pa_haproxy_password => $atomia_pa_haproxy_password
       }
}

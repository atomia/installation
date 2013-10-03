# modules/domain_controller/params.pp

class domain_controller::params {
       $domain_name = 'ad.atomia.com'
       $netbios_name = 'ad'
       $dc_ip = '127.0.0.1'
       $domain_password = 'xiMZa3jBpuvifBJwjRrtxNPcLTwh4YFZ'
       $is_master = true
       $admin_user = "Administrator"
       $admin_password = "Abc123"

}
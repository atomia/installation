# SSH public key, will be distributed to all servers 
$atomia_public_key = ""
$atomia_public_key_user = "root"

# Password for the application pool user, should be a random string 
# of good complexity.
$app_password = "#RANDOM_STRING" 

##### ACTIVE DIRECTORY SETTINGS ##############################
# Active directory domain name for the environment
$ad_domain = ""
$ad_shortname = ""

# Active directory domain administrator username and password
# almost always "Administrator"    
$admin_user = "Administrator"
$admin_user_password = "#RANDOM_STRING"

# Active directory config
$base_dn = "cn=Users,dc=xxx,dc=xxx"
$ldap_uris = "ldap://ad1.xxx.com ldap://ad2.xxx.com"

# User that guests use to bind to the AD, make sure this user exists
$bind_user = "PosixGuest"
$bind_password = "#RANDOM_STRING"

$windows_guest_user = "WindowsGuest"
$windows_guest_password = "#RANDOM_STRING"

# Ip address of the main domain controller
$dc_ip = "" 
##############################################################

# Ip address of the Atomia database server
$database_server = ""

# Main domain for the environment for example atomia.com (for an env with hcp.atomia.com, order.atomia.com)
$appdomain = ""

# Hostname to use for Atomia applications
$actiontrail = "actiontrail"
$login = "login"
$order = "order"
$billing = "billing"
$admin = "admin"
$hcp = "hcp"
$automationserver = "automationserver"

# Thumbprints for the encrypton certificates
$automationserver_encryption_cert_thumb = ""
$billing_encryption_cert_thumb = ""
$root_cert_thumb = ""
$signing_cert_thumb = ""

# Billing plugin to use
# TODO: Is this obsolete?
$billing_plugin_config = "Atomia.Billing.Plugins.Demo.Configuration.PluginsConfiguration, Atomia.Billing.Plugins.Demo.Configuration"
$send_invoice_email_subject_format = "Faktura - {0}"

# Domainreg
$domainreg_service_url = "http://domainreg.xxx.com/domainreg"
$domainreg_service_username = "domainregistration"
$domainreg_service_password = "#RANDOM_STRING"
$atomia_domainreg_opensrs_user = ""
$atomia_domainreg_opensrs_pass = ""
$atomia_domainreg_opensrs_url =  "https://horizon.opensrs.net:55443/"
$atomia_domainreg_opensrs_tlds = "com;net;org;info"
$atomia_domainreg_opensrs_only = "true"

# Ip address of the server hosting Action Trail
$actiontrail_ip = ""

# SMTP information, outgoing mail will be sent with this server
$mail_sender_address = "noreply@xxx.com"
$mail_server_host = ""
$mail_server_port = "25"
$mail_server_username = ""
$mail_server_password = ""
$mail_server_use_ssl = "false"
$mail_bcc_list = ""
$mail_reply_to = ""

$storage_server_hostname = "10.11.11.10"
$mail_dispatcher_interval = "30"

# DNS configuration
$atomia_dns_ns_group = "atomia"
$ssl_enabled = "true"
$atomia_dns_agent_user = "atomiadns"
$atomia_dns_agent_password = "#RANDOM_STRING"
$atomia_dns_url = "http://xxx.com/atomiadns"
$nameserver1 = "ns1.xxx.com"
$nameservers = "\"[ns1.xxx.com,ns2.xxx.com]\"" #Maximium 2
$registry = "registry.xxx.com"
$ssl_cert_key = "-----BEGIN RSA PRIVATE KEY-----
xxx
-----END RSA PRIVATE KEY-----"
$ssl_cert_file = "-----BEGIN CERTIFICATE-----
xxx
-----END CERTIFICATE-----"

# Dns zones added at installation time, usually no change needed here
$atomia_dns_zones_to_add = "preview.#{$appdomain}\nmysql.#{$appdomain}\nmssql.#{$appdomain}\ncloud.#{$appdomain}"


# CRON agent config
$cronagent_base_url = "http://xxx.com:10101"
# Random string
$cronagent_global_auth_token = "#RANDOM_STRING"
$cronagent_min_part = 0
$cronagent_max_part = 1000
$cronagent_mail_host = "localhost"
$cronagent_mail_port = 25
$cronagent_mail_ssl = false
$cronagent_mail_from = "cron@xxx.com"
$cronagent_mail_user = ""
$cronagent_mail_pass = ""  

# NFS Configuration
$use_nfs3 = true
$atomia_web_content_nfs_location = "127.0.0.1:/volumes/web"
$atomia_web_content_mount_point = "/storage/content"
$atomia_web_config_nfs_location = "127.0.0.1:/volumes/config"
$atomia_web_config_mount_point = "/storage/configuration"
$atomia_mail_storage_nfs_location = "127.0.0.1:/volumes/mail"
$apache_conf_dir = "apache"
$iis_config_dir = "iis"

# Customer Mysql servers
$number_of_mysql_servers = 1
$mysql_ip_address = ["127.0.0.1"]
$mysql_username = "atomiaprov" #Max 16 characters
$mysql_password = "#RANDOM_STRING"
# Ip of server running automation server
$provisioning_host = ""

# Customer MSsql servers
$number_of_mssql_servers = 1
$mssql_ip_address = ["127.0.0.1"]
$mssql_username = "atomiaprov" #Max 16 characters
$mssql_password = "#RANDOM_STRING"

#Daggre 
$daggre_global_auth_token = "#RANDOM_STRING"
$daggre_ip_addr = ""

#Awstats
$awstats_agent_user = "awstatsagent"
$awstats_agent_user_agent_password = "#RANDOM_STRING"
$awstats_ip = ""

#File system agent
$fs_agent_user = "filesystemagent"
$fs_agent_password = "#RANDOM_STRING"
$fs_agent_ip = ""

# Webinstaller
$webinstaller_username = "webinstaller"
$webinstaller_password = "#RANDOM_STRING"
$webinstaller_ip = ""

# Pureftpd
$pureftpd_agent_user = "pureftpagent"
$pureftpd_agent_password = "#RANDOM_STRING"
$pureftpd_master_ip = ""
$pureftpd_password = "#RANDOM_STRING"
$pureftpd_slave_password = "#RANDOM_STRING"
$ftp_cluster_ip = ""

# Apache Agent
$apache_agent_user = "apacheagent"
$apache_agent_password = "#RANDOM_STRING" 
$apache_agent_ip = ""
$apache_cluster_ip = ""

# Mail config
$mail_slave_password  = "#RANDOM_STRING"
$atomia_mail_agent_password = "#RANDOM_STRING"
$atomia_mail_master_ip = ""
$atomia_mail_cluster_ip = ""

# IIS 
$iis_master_ip = ""

# HAPROXY
$atomia_pa_haproxy_user = "atomia-agent"
$atomia_pa_haproxy_password = "#RANDOM_STRING"


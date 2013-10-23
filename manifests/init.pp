# Define: cobbler
#
# This class manages Cobbler
# https://fedorahosted.org/cobbler/
#
# Parameters:
#
#   - $service_name [type: string]
#     Name of the cobbler service, defaults to 'cobblerd'.
#
#   - $package_name [type: string]
#     Name of the installation package, defaults to 'cobbler'
#
#   - $package_ensure [type: string]
#     Defaults to 'present', buy any version can be set
#
#   - $distro_path [type: string]
#     Defines the location on disk where distro files will be
#     stored. Contents of the ISO images will be copied over
#     in these directories, and also kickstart files will be
#     stored. Defaults to '/distro'
#
#   - $manage_dhcp [type: bool]
#     Wether or not to manage ISC DHCP.
#
#   - $dhcp_dynamic_range [type: string]
#     Range for DHCP server
#
#   - $manage_dns [type: string]
#     Wether or not to manage DNS
#
#   - $dns_option [type: string]
#     Which DNS deamon to manage - Bind or dnsmasq. If dnsmasq,
#     then dnsmasq has to be used for DHCP too.
#
#   - $manage_tftpd [type: bool]
#     Wether or not to manage TFTP daemon.
#
#   - $tftpd_option [type:string]
#     Which TFTP daemon to use.
#
#   - $server_ip [type: string]
#     IP address of a server.
#
#   - $next_server_ip [type: string]
#     Next Server in cobbler config.
#
#   - $nameserversa [type: array]
#     Nameservers for kickstart files to put in resolv.conf upon
#     installation.
#
#   - $dhcp_interfaces [type: array]
#     Interface for DHCP to listen on.
#
#   - $dhcp_subnets [type: array]
#     If you use *DHCP relay* on your network, then $dhcp_interfaces
#     won't suffice. $dhcp_subnets have to be defined, otherwise,
#     DHCP won't offer address to a machine in a network that's
#     not directly available on the DHCP machine itself.
#
#   - $defaultrootpw [type: string]
#     Hash of root password for kickstart files.
#
#   - $apache_service [type: string]
#     Name of the apache service.
#
#   - $allow_access [type: string]
#     For what IP addresses/hosts will access to cobbler_api be granted.
#     Default is for server_ip, ::ipaddress and localhost
#
#   - $purge_distro  [type: bool]
#   - $purge_repo    [type: bool]
#   - $purge_profile [type: bool]
#   - $purge_system  [type: bool]
#     Decides wether or not to purge (remove) from cobbler distro,
#     repo, profiles and systems which are not managed by puppet.
#     Default is true.
#
#   - default_kickstart [type: string]
#     Location of the default kickstart. Default depends on $::osfamily.
#
#   - webroot [type: string]
#     Location of Cobbler's web root. Default: '/var/www/cobbler'.
#
# Actions:
#   - Install Cobbler
#   - Manage Cobbler service
#
# Requires:
#   - puppetlabs/apache class
#     (http://forge.puppetlabs.com/puppetlabs/apache)
#
# Sample Usage:
#
define cobbler (
  $defaultrootpw,
  $service_name                    = 'cobblerd',
  $package_name                    = 'cobbler',
  $package_ensure                  = 'present',
  $distro_path                     = '/distro',
  $manage_dhcp                     = 0,
  $dhcp_template                   = 'cobbler/dhcp.template.erb',
  $dhcp_dynamic_range              = 0,
  $manage_dns                      = 0,
  $dns_option                      = 'dnsmasq',
  $dhcp_option                     = 'isc',
  $manage_tftpd                    = 1,
  $manage_rsync                    = 1,
  $tftpd_option                    = 'in_tftpd',
  $server_ip                       = $::ipaddress,
  $next_server_ip                  = $::ipaddress,
  $nameservers                     = '127.0.0.1',
  $dhcp_interfaces                 = 'eth0',
  $dhcp_subnets                    = '',
  $apache_service                  = 'httpd',
  $allow_access                    = "${server_ip} ${::ipaddress} 127.0.0.1",
  $reporting_enabled               = 1,
  $reporting_sender                = "Cobbler Server - ${::ipaddress}",
  $reporting_email                 = "root",
  $register_new_installs           = 0,
  $pretty_json                     = 0,
  $scm_enabled                     = 0,
  $keep_repos                      = 1,
  $purge_distro                    = false,
  $purge_repo                      = false,
  $purge_profile                   = false,
  $purge_system                    = false,
  $puppet_auto_setup               = 1,
  $sign_puppet_certs_automatically = 1,
  $createrepo_flags                = '-c cache -s sha',
  $default_kickstart               = '/var/lib/cobbler/kickstarts/default.ks',
  $webroot                         = '/var/www/cobbler',
  $www_html_dir                    = '/var/www/html',
  $http_config_prefix              = '/etc/httpd/conf.d',
  $proxy_config_prefix             = '/etc/httpd/conf.d',
  $authn_module                    = 'authn_denyall',
  $authz_module                    = 'authz_allowall',
  $role                            = 'primary',
  $tftp_package                    = 'tftp-server',
  $syslinux_package                = 'syslinux',
  $ldap_server                     = "example.com",
  $ldap_base_dn                    = "DC=example,DC=com",
  $ldap_port                       = 389,
  $ldap_tls_enabled                = 0,
  $ldap_anonymous_enabled          = 1,
  $ldap_bind_dn                    = '',
  $ldap_bind_passwd                = '',
  $ldap_search_prefix              = 'uid=',
  $ldap_tls_cacert                 = '',
  $ldap_tls_key                    = '',
  $ldap_tls_cert                   = '',
  $admin_users                     = ['admin','cobbler']
) {

  # require apache modules
  if ! defined(Class['apache']) {
    class { 'apache':
      default_mods      => true,
      default_vhost     => false,
      default_ssl_vhost => true,
    }
  }
  file { "${http_config_prefix}/15-default.conf":
    content => template('cobbler/15-default.conf.erb'),
    notify  => Service[$apache_service],
  }
  if ! defined(Class['apache::mod::wsgi']) {
    class { 'apache::mod::wsgi':
    }
  }
  if ! defined(Class['apache::mod::proxy']) {
    class { 'apache::mod::proxy':
    }
  }
  if ! defined(Class['apache::mod::proxy_http']) {
    class { 'apache::mod::proxy_http':
    }
  }

  # install section
  if ! defined(Package['python-ldap']) {
    package { 'python-ldap':     ensure => present, }
  }
  if ! defined(Package['xinetd']) {
    package { 'xinetd':     ensure => present, }
  }
  if ! defined(Package['git']) {
    package { 'git':             ensure => present, }
  }
  if ! defined(Package['debmirror']) {
    package { 'debmirror':             ensure => present, }
  }
  if ! defined(Package['pykickstart']) {
    package { 'pykickstart':             ensure => present, }
  }
  if ! defined(Package['hardlink']) {
    package { 'hardlink':             ensure => present, }
  }
  if ! defined(Package['cman']) {
    package { 'cman':             ensure => present, }
  }
  if ! defined(Package['fence-agents']) {
    package { 'fence-agents':             ensure => present, }
  }
  package { $tftp_package:     ensure => present, }
  package { $syslinux_package: ensure => present, }
  package { $package_name:
    ensure  => $package_ensure,
    require => [ Package[$syslinux_package], Package[$tftp_package], Package['python-ldap'], Package['xinetd'], Package['git'] ],
  }

  service { $service_name :
    ensure  => running,
    enable  => true,
    require => Package[$package_name],
  }

  if ! defined(Service['xinetd']) {
    service { 'xinetd' :
      ensure  => running,
      enable  => true,
      require => Package['xinetd'],
    }
  }

  # file defaults
  File {
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0644',
  }
  file { "${proxy_config_prefix}/proxy_cobbler.conf":
    content => template('cobbler/proxy_cobbler.conf.erb'),
    notify  => Service[$apache_service],
  }
  file { "/etc/xinetd.d/rsync":
    source => 'puppet:///modules/cobbler/xinetd-rsync',
    notify  => Service['xinetd'],
  }
  file { "/etc/debmirror.conf":
    source => 'puppet:///modules/cobbler/debmirror.conf',
    require => Package['debmirror'],
  }
  file { $distro_path :
    ensure => directory,
    mode   => '0755',
  }
  file { "${distro_path}/kickstarts" :
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/cobbler/settings':
    content => template('cobbler/settings.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { '/etc/cobbler/modules.conf':
    content => template('cobbler/modules.conf.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { '/etc/cobbler/users.conf':
    content => template('cobbler/users.conf.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { "${http_config_prefix}/distros.conf":
    content => template('cobbler/distros.conf.erb'),
    notify  => Service[$apache_service],
  }
  file { "${http_config_prefix}/cobbler.conf":
    content => template('cobbler/cobbler.conf.erb'),
    notify  => Service[$apache_service],
  }
  if ! defined(File["${www_html_dir}/index.html"]) {
    file { "${www_html_dir}/index.html":
      content => template('cobbler/index.html.erb'),
      require => Service[$apache_service],
    }
  }

  # cobbler sync command
  exec { 'cobblersync':
    command     => '/usr/bin/cobbler sync',
    refreshonly => true,
    require     => Service[$service_name],
    notify      => Exec['cobblerget-loaders'],
  }

  # cobbler get-loaders command
  # We really only need to run this once, but it won't hurt.
  exec { 'cobblerget-loaders':
    command     => '/usr/bin/cobbler get-loaders --force',
    refreshonly => true,
    require     => Service[$service_name],
  }

  # purge resources
  if $purge_distro == true {
    resources { 'cobblerdistro':  purge => true, }
  }
  if $purge_repo == true {
    resources { 'cobblerrepo':    purge => true, }
  }
  if $purge_profile == true {
    resources { 'cobblerprofile': purge => true, }
  }
  if $purge_system == true {
    resources { 'cobblersystem':  purge => true, }
  }

  # include ISC DHCP only if we choose manage_dhcp
  if $manage_dhcp == '1' {
    package { 'dhcp':
      ensure => present,
    }
    service { 'dhcpd':
      ensure  => running,
      enable  => true,
      require => Package['dhcp'],
    }
    file { '/etc/cobbler/dhcp.template':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template($dhcp_template),
      require => Package[$package_name],
      notify  => Exec['cobblersync'],
    }
  }

  # logrotate script
  file { '/etc/logrotate.d/cobbler':
    source => 'puppet:///modules/cobbler/logrotate',
  }

  # cobbler reposync cron script
  file { '/etc/cron.daily/cobbler-reposync':
    source => 'puppet:///modules/cobbler/cobbler-reposync.cron',
    mode   => '0755',
  }

}
# vi:nowrap:

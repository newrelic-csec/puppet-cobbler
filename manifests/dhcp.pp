# Define: cobbler::dhcp
#
# This module manages ISC DHCP for Cobbler
# https://fedorahosted.org/cobbler/
#
define cobbler::dhcp (
  $nameservers     = $::cobbler::params::nameservers,
  $dhcp_interfaces = $::cobbler::params::dhcp_interfaces,
  $dhcp_template   = $::cobbler::params::dhcp_template,
  ) {
  package { 'dhcp':
    ensure => present,
  }
  service { 'dhcpd':
    ensure  => running,
    require => Package['dhcp'],
  }
  file { '/etc/cobbler/dhcp.template':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($dhcp_template),
  }
}

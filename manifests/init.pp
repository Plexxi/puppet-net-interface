# == Class: net-interface
#
# Manage /etc/network/interfaces.d/IFACE file for Debian system.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
# IPv4 disabled; IPv6 use DHCP no options
#  class { 'net-interface': 'mgmt',
#    disable4 => true,
#    dhcp6 => {},
#  }
#
# IPv4 use DHCP w/ options; IPv6 static params w/ extra static routes
#  class { 'net-interface': 'mgmt',
#    dhcp4 => { hostname => 'me.here',
#               leasetime => 3600,
#             },
#    static6 => { addrs => [ '2002:c000:203::1/64',
#                            '2002:c000:203::9/64', ],
#                 gateway => '2002:c000:203::ff',
#               },
#    routes6 => { '42::f00d/120' => '2002:c000:203::10ff',
#                 '999:007:1234:abcd::/72' => '2002:c000:203::20ff', },
#  }
#
# IPv4 static params; IPv6 disabled
#  class { 'net-interface': 'mgmt',
#    static4 => { addrs => [ '1.2.3.4/16', ],
#                 gateway => '1.2.3.254',
#                 mtu => 1500,
#               },
#    disable6 => true,
#  }
#
# === Authors
#
# Joe Lorenz <joe.lorenz@plexxi.com>
#
# === Copyright
#
# Copyright 2017 Joe Lorenz, Plexxi Inc.
#
class net-interface (
  $ifname = undef,
#  $hwaddress = undef,

  # IPv4
  $disable4 = false,
  $metric4 = undef,
  $dhcp4 = undef,
  $static4 = undef,

  # IPv6
  $disable6 = false,
  $dhcp6 = undef,
  $static6 = undef,

  # Static routes
  $routes4 = undef,
  $routes6 = undef,

) {
  $interfaces_dir = '/etc/network/interfaces.d'
  $required_pkgs = [ 'iproute2', 'isc-dhcp-client' ]

  if $osfamily != 'Debian' {
    fail('This module supports Debian (jessie, and possibly later versions) only.')
  }

  package { $required_pkgs: ensure => 'installed', }

# Validations
  define my_validate_ipv4_prefix {
    $tmp = split($name, '/')
    validate_ipv4_address($tmp[0])
    validate_re($tmp[1], '^[0-9]{1,2}$', "address $name is not a valid IPv4 address/mask")
    $mask = 0 + $tmp[1]
    if $mask < 0 or $mask > 32 {
      fail("address $name is not a valid IPv4 address/mask")
    }
  }

  define my_validate_ipv4_address {
    validate_ipv4_address($name)
  }

  define my_validate_ipv6_prefix {
        $tmp = split($name, '/')
        validate_ipv6_address($tmp[0])
        validate_re($tmp[1], '^[0-9]{1,3}$', "address $name is not a valid IPv6 address/mask")
        $mask = 0 + $tmp[1]
        if $mask < 0 or $mask > 128 {
          fail("address $name is not a valid IPv6 address/mask")
        }
  }

  define my_validate_ipv6_address {
    validate_ipv6_address($name)
  }

  if $ifname {
    validate_string($ifname)
  }
  else {
    fail('ifname - interface name value is required')
  }

#  if $hwaddress {
#    $cfg_hwaddress = $hwaddress
#  }
  if $ifname == 'mgmt' {
    $cfg_hwaddress = chomp(file('/plexxi/1/chassis/eeprom/mgmt_mac'))
  }
  if $cfg_hwaddress and !is_mac_address($cfg_hwaddress) {
    fail('hwaddress - invalid MAC')
  }

  validate_bool($disable4)

  if $metric4 and !is_integer($metric4) {
    fail('metric4 - expected integer value')
  }

  if $dhcp4 {
    if $static4 { fail('cannot specify both dhcp4 and static4') }
    if $disable4 and $disable4 == true { fail('cannot specify both dhcp4 and disable4') }
    validate_hash($dhcp4)
    if has_key($dhcp4, hostname) {
      $hostname4 = $dhcp4[hostname]
      validate_re($hostname4, '^(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)$', 'dhcp4 hostname is invalid')
    }
    if has_key($dhcp4, leasetime) {
      $leasetime4 = $dhcp4[leasetime]
      if !is_integer($leasetime4) {
        fail('dhcp4 leasetime - expected integer number of minutes')
      }
    }
    if has_key($dhcp4, vendor) {
      $vendor4 = $dhcp4[vendor]
      validate_string($vendor4)
    }
    if has_key($dhcp4, client) {
      $client4 = $dhcp4[client]
      validate_string($client4)
    }
  }

  if $static4 {
    if $dhcp4 { fail('cannot specify both dhcp4 and static4') }
    if $disable4 and $disable4 == true { fail('cannot specify both static4 and disable4') }
    validate_hash($static4)
    if has_key($static4, addrs) {
      $addrs4 = $static4[addrs]
      validate_array($addrs4)
      my_validate_ipv4_prefix { $addrs4: }
    }
    else {
      fail('static4 - must specify one or more address/mask entries')
    }
    if has_key($static4, gateway) {
      $gateway4 = $static4[gateway]
      validate_ipv4_address($gateway4)
    }
    else {
      fail('static4 - must specify a gateway')
    }
    if has_key($static4, mtu) {
      $mtu4 = $static4[mtu]
      if !is_integer($mtu4) {
        fail('static4 mtu - expected integer value')
      }
    }
  }

  validate_bool($disable6)

  if $dhcp6 {
    if $static6 { fail('cannot specify both dhcp6 and static6') }
    if $disable6 and $disable6 == true { fail('cannot specify both dhcp6 and disable6') }
    validate_hash($dhcp6)
    if has_key($dhcp6, hostname) {
      $hostname6 = $dhcp6[hostname]
      validate_re($hostname6, '^(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)$', 'dhcp6 hostname is invalid')
    }
    if has_key($dhcp6, leasetime) {
      $leasetime6 = $dhcp6[leasetime]
      if !is_integer($leasetime6) {
        fail('dhcp6 leasetime - expected integer number of minutes')
      }
    }
    if has_key($dhcp6, vendor) {
      $vendor6 = $dhcp6[vendor]
      validate_string($vendor6)
    }
    if has_key($dhcp6, client) {
      $client6 = $dhcp6[client]
      validate_string($client6)
    }
  }

  if $static6 {
    if $dhcp6 { fail('cannot specify both dhcp6 and static6') }
    if $disable6 and $disable6 == true { fail('cannot specify both static6 and disable6') }
    validate_hash($static6)
    if has_key($static6, addrs) {
      $addrs6 = $static6[addrs]
      validate_array($addrs6)
      my_validate_ipv6_prefix { $addrs6: }
    }
    else {
      fail('static6 - must specify one or more address/mask entries')
    }
    if has_key($static6, gateway) {
      $gateway6 = $static6[gateway]
      validate_ipv6_address($gateway6)
    }
    else {
      fail('static6 - must specify a gateway')
    }
    if has_key($static6, mtu) {
      $mtu6 = $static6[mtu]
      if !is_integer($mtu6) {
        fail('static6 mtu - expected integer value')
      }
    }
  }

  if $routes4 {
    validate_hash($routes4)
    $nets = keys($routes4)
    my_validate_ipv4_prefix { $nets: }
    $nhops = values($routes4)
    my_validate_ipv4_address { $nhops: }
  }

  if $routes6 {
    validate_hash($routes6)
    $nets6 = keys($routes6)
    my_validate_ipv6_prefix { $nets6: }
    $nhops6 = values($routes6)
    my_validate_ipv6_address { $nhops6: }
  }

  #notice("ifname - $ifname")
  #notice("cfg_hwaddress - $cfg_hwaddress")
  #notice("disable4 - $disable4")
  #notice("metric4 - $metric4")
  #notice("dhcp4 - $dhcp4")
  #notice("static4 - $static4")
  #notice("disable6 - $disable6")
  #notice("dhcp6 - $dhcp6")
  #notice("static6 - $static6")
  #notice("routes4 - $routes4")
  #notice("routes6 - $routes6")


# Actions
  $target = "/etc/network/interfaces.d/${ifname}"
  validate_absolute_path($target)
  $tmp_target = "/tmp/plexxi-net-interface_${ifname}.tmp"
  validate_absolute_path($tmp_target)

  file { $tmp_target:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template('plexxi-net-interface/interfaces.erb'),
  }

  exec { "${ifname}-configure":
    unless => "/usr/bin/cmp -s ${tmp_target} ${target}",
    command => "/sbin/ifdown ${ifname}; /bin/cp -a ${tmp_target} ${target}",
    require => $tmp_target,
  } -> exec { "${ifname}-up":
    unless => "/usr/bin/test ${disable4} = true -a ${disable6} = true",
    command => "/sbin/ifup ${ifname}",
    require => $target,
  }
}

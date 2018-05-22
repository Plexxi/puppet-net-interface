# == Class: net_interface
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
#  class { 'net_interface':
#    ifname => 'mgmt',
#    disable4 => true,
#    dhcp6 => {},
#  }
#
# IPv4 use DHCP w/ options; IPv6 static params w/ extra static routes
#  class { 'net_interface':
#    ifname => 'mgmt',
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
#  class { 'net_interface':
#    ifname => 'mgmt',
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
# Matthew Morgan <matt.morgan@plexxi.com>
#
# === Copyright
#
# Copyright 2017 Joe Lorenz, Plexxi Inc.
# Copyright 2018 Matthew Morgan, Plexxi Inc.
#

# Types
type Ip_v4_cidr = Pattern[/\A([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\/([1-9]|[12][0-9]|3[0-2])?\z/]

type Ip_v4_nosubnet = Pattern[/\A([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/]

type Ip_v6_alternative = Pattern[
  /\A([[:xdigit:]]{1,4}:){6}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){5}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){4}(:[[:xdigit:]]{1,4}){0,1}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){3}(:[[:xdigit:]]{1,4}){0,2}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){2}(:[[:xdigit:]]{1,4}){0,3}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){1}(:[[:xdigit:]]{1,4}){0,4}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A:(:[[:xdigit:]]{1,4}){0,5}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
]

type Ip_v6_compressed = Pattern[
  /\A:(:|(:[[:xdigit:]]{1,4}){1,7})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){1}(:|(:[[:xdigit:]]{1,4}){1,6})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){2}(:|(:[[:xdigit:]]{1,4}){1,5})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){3}(:|(:[[:xdigit:]]{1,4}){1,4})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){4}(:|(:[[:xdigit:]]{1,4}){1,3})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){5}(:|(:[[:xdigit:]]{1,4}){1,2})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){6}(:|(:[[:xdigit:]]{1,4}){1,1})(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
  /\A([[:xdigit:]]{1,4}:){7}:(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/,
]

type Ip_v6_full = Pattern[/\A[[:xdigit:]]{1,4}(:[[:xdigit:]]{1,4}){7}(\/(1([01][0-9]|[2][0-8])|[1-9][0-9]|[1-9]))?\z/]

type Ip_v6_alternative_nosubnet = Pattern[
  /\A([[:xdigit:]]{1,4}:){6}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A([[:xdigit:]]{1,4}:){5}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A([[:xdigit:]]{1,4}:){4}(:[[:xdigit:]]{1,4}){0,1}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A([[:xdigit:]]{1,4}:){3}(:[[:xdigit:]]{1,4}){0,2}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A([[:xdigit:]]{1,4}:){2}(:[[:xdigit:]]{1,4}){0,3}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A([[:xdigit:]]{1,4}:){1}(:[[:xdigit:]]{1,4}){0,4}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
  /\A:(:[[:xdigit:]]{1,4}){0,5}:([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}\z/,
]

type Ip_v6_compressed_nosubnet = Pattern[
  /\A:(:|(:[[:xdigit:]]{1,4}){1,7})\z/,
  /\A([[:xdigit:]]{1,4}:){1}(:|(:[[:xdigit:]]{1,4}){1,6})\z/,
  /\A([[:xdigit:]]{1,4}:){2}(:|(:[[:xdigit:]]{1,4}){1,5})\z/,
  /\A([[:xdigit:]]{1,4}:){3}(:|(:[[:xdigit:]]{1,4}){1,4})\z/,
  /\A([[:xdigit:]]{1,4}:){4}(:|(:[[:xdigit:]]{1,4}){1,3})\z/,
  /\A([[:xdigit:]]{1,4}:){5}(:|(:[[:xdigit:]]{1,4}){1,2})\z/,
  /\A([[:xdigit:]]{1,4}:){6}(:|(:[[:xdigit:]]{1,4}){1,1})\z/,
  /\A([[:xdigit:]]{1,4}:){7}:\z/,
]

type Ip_v6_full_nosubnet = Pattern[/\A[[:xdigit:]]{1,4}(:[[:xdigit:]]{1,4}){7}\z/]

type Ip_v6 = Variant[Ip_v6_alternative, Ip_v6_compressed, Ip_v6_full]

type Ip_v6_nosubnet = Variant[Ip_v6_alternative_nosubnet, Ip_v6_compressed_nosubnet, Ip_v6_full_nosubnet]

# Class
class net_interface (
  String $ifname = undef,
#  $hwaddress = undef,

  # IPv4
  Boolean $disable4 = false,
  Optional[Struct[{ Optional[hostname]  => Pattern[/\A(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\Z/],
                    Optional[leasetime] => Integer,
                    Optional[metric]    => Integer,
                    Optional[vendor]    => String[1],
                    Optional[client]    => String[1],
                  }]] $dhcp4 = undef,
  Optional[Struct[{ addrs               => Array[Ip_v4_cidr],
                    Optional[gateway]   => Ip_v4_nosubnet,
                    Optional[metric]    => Integer,
                    Optional[mtu]       => Integer,
                  }]] $static4 = undef,

  # IPv6
  Boolean $disable6 = false,
  Optional[Struct[{ Optional[accept_ra] => Enum['off', 'on', 'on+forwarding'],
                  }]] $dhcp6 = undef,
  Optional[Struct[{ addrs               => Array[Ip_v6],
                    Optional[gateway]   => Ip_v6_nosubnet,
                    Optional[mtu]       => Integer,
                    Optional[privext]   => Enum['off', 'assign', 'prefer'],
                    Optional[accept_ra] => Enum['off', 'on', 'on+forwarding'],
                  }]] $static6 = undef,
  Optional[Struct[{ Optional[privext]   => Enum['off', 'assign', 'prefer'],
                    Optional[accept_ra] => Enum['off', 'on', 'on+forwarding'],
                    Optional[dhcp]      => Boolean,
                  }]] $auto6 = undef,

  # Static routes
  Optional[Hash[ Ip_v4_cidr, Ip_v4_nosubnet ]] $routes4 = undef,
  Optional[Hash[ Ip_v6, Ip_v6_nosubnet ]] $routes6 = undef,

) {
  $interfaces_dir = '/etc/network/interfaces.d'
  $required_pkgs = [ 'iproute2', 'isc-dhcp-client' ]

  if $osfamily != 'Debian' {
    fail('This module supports Debian (stretch, and possibly later versions) only.')
  }

  package { $required_pkgs: ensure => 'installed', }

# Validations
  if $ifname == undef or $ifname == "" {
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

  if $dhcp4 {
    if $static4 { fail('cannot specify both dhcp4 and static4') }
    if $disable4 and $disable4 == true { fail('cannot specify both dhcp4 and disable4') }
    if has_key($dhcp4, metric) {
      $metric4 = $dhcp4[metric]
    }
    if has_key($dhcp4, hostname) {
      $hostname4 = $dhcp4[hostname]
    }
    if has_key($dhcp4, leasetime) {
      $leasetime4 = $dhcp4[leasetime]
    }
    if has_key($dhcp4, vendor) {
      $vendor4 = $dhcp4[vendor]
    }
    if has_key($dhcp4, client) {
      $client4 = $dhcp4[client]
    }
  }

  if $static4 {
    if $dhcp4 { fail('cannot specify both dhcp4 and static4') }
    if $disable4 and $disable4 == true { fail('cannot specify both static4 and disable4') }
    if has_key($static4, addrs) {
      $addrs4 = $static4[addrs]
    }
    if has_key($static4, gateway) {
      $gateway4 = $static4[gateway]
    }
    if has_key($static4, metric) {
      $metric4 = $static4[metric]
    }
    if has_key($static4, mtu) {
      $mtu4 = $static4[mtu]
    }
  }

  if $dhcp6 {
    if $static6 { fail('cannot specify both dhcp6 and static6') }
    if $disable6 and $disable6 == true { fail('cannot specify both dhcp6 and disable6') }
    if $auto6 { fail('cannot specify both dhcp6 and auto6') }
    if has_key($dhcp6, accept_ra) {
      $dhcp6_accept_ra = downcase($dhcp6[accept_ra])
    }
  }

  if $static6 {
    if $dhcp6 { fail('cannot specify both dhcp6 and static6') }
    if $disable6 and $disable6 == true { fail('cannot specify both static6 and disable6') }
    if $auto6 { fail('cannot specify both static6 and auto6') }

    if has_key($static6, addrs) {
      $addrs6 = $static6[addrs]
    }
    if has_key($static6, gateway) {
      $gateway6 = $static6[gateway]
    }
    if has_key($static6, mtu) {
      $mtu6 = $static6[mtu]
    }
    if has_key($static6, privext) {
      $static6_privext = downcase($static6[privext])
    }
    if has_key($static6, accept_ra) {
      $static6_accept_ra = downcase($static6[accept_ra])
    }
  }

  if $auto6 {
    if $dhcp6 { fail('cannot specify both dhcp6 and auto6') }
    if $disable6 and $disable6 == true { fail('cannot specify both auto6 and disable6') }
    if $static6 { fail('cannot specify both auto6 and static6') }

    if has_key($auto6, privext) {
      $auto6_privext = downcase($auto6[privext])
    }
    if has_key($auto6, accept_ra) {
      $auto6_accept_ra = downcase($auto6[accept_ra])
    }
    if has_key($auto6, dhcp) {
      $auto6_dhcp = $auto6[dhcp]
    }
  }

  #notice("ifname - $ifname")
  #notice("cfg_hwaddress - $cfg_hwaddress")
  #notice("disable4 - $disable4")
  #notice("dhcp4 - $dhcp4")
  #notice("static4 - $static4")
  #notice("disable6 - $disable6")
  #notice("dhcp6 - $dhcp6")
  #notice("auto6 - $auto6")
  #notice("static6 - $static6")
  #notice("routes4 - $routes4")
  #notice("routes6 - $routes6")


# Actions
  $target = "/etc/network/interfaces.d/${ifname}"
  validate_legacy(Stdlib::Compat::Absolute_Path, validate_absolute_path, $target)
  $tmp_target = "/tmp/plexxi-net-interface_${ifname}.tmp"
  validate_legacy(Stdlib::Compat::Absolute_Path, validate_absolute_path, $tmp_target)

  file { $tmp_target:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template("${module_name}/interfaces.erb"),
  }

  exec { "${ifname}-configure":
    unless => "/usr/bin/cmp -s ${tmp_target} ${target}",
    command => "/sbin/ifdown ${ifname}; /sbin/ip -f inet addr flush dev ${ifname}; /sbin/ip -f inet6 addr flush dev ${ifname}; /bin/cp -a ${tmp_target} ${target}",
    require => File[$tmp_target],
  } -> exec { "${ifname}-up":
    unless => "/usr/bin/test ${disable4} = true -a ${disable6} = true",
    command => "/sbin/ifup ${ifname}",
#    require => $target,
  }
}

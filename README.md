# net-interface

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Static IPv4](#static-ipv4)
    * [DHCP IPv4](#dhcp-ipv4)
    * [Disabled IPv4](#disabled-ipv4)
    * [Static IPv6](#static-ipv6)
    * [DHCP IPv6](#dhcp-ipv6)
    * [Disabled IPv6](#disabled-ipv6)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Parameters](#parameters)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This puppet module manages network interface settings for config file to be
placed under ```/etc/network/interfaces.d/IFNAME``` on a Debian system. This was
specifically written to handle multiple addresses per interface as well as
support IPv6 settings.

## Module Description

Any declaration of ```net-interface``` class will cause this puppet module to
take control of the file ```/etc/network/interfaces.d/IFNAME``` where IFNAME is
specified with the ```ifname``` parameter to the class. Thus, ```ifname``` is a
REQUIRED parameter.

The module allows for static, or DHCP-based configuration for both IPv4 and
IPv6. Static configs allow for multiple addresses to be assigned, as well as
defining additional static routes. Either IPv4 or IPv6 can be set as "disabled"
which essentially leaves that family unconfigured for the interface. If BOTH
IPv4 and IPv6 are set as "disabled", the interface is left disabled entirely.

The module actions are as follows: the interface is brought down using
```ifdown IFNAME```, the config file is modified as specified, and the interface
is brought up (if applicable) using ```ifup IFNAME```. If the definitions being
applied cause no change in the config file, then no further action is performed
on the interface.

## Usage

The ```ifname``` parameter is **required**.
Any of the IPv4 methods can be combined with any of the IPv6 methods, but you
can NOT specify more than one method for either family.

### Static IPv4

For static IPv4 configuration, specify at least one address/mask to assign. You can optionally specify default gateway, MTU, or metric.

The ```routes4``` parameter can be used to specify a list of static routes and
their next-hops to be added when the interface is brought up.

Examples:
```puppet
class { 'net-interface':
  ifname   => 'eth0',
  static4  => { addrs => [ '1.2.3.4/24', ],
                gateway => '1.2.3.254',
                mtu => 1500,
              },
  disable6 => true,
}
```

```puppet
class { 'net-interface':
  ifname   => 'eth0',
  static4  => { addrs   => [ '172.17.205.2/16',
                             '5.6.7.8/16', ],
                gateway => '172.17.214.1',
              },
  routes4  => { '10.11.12.0/24' => '172.17.214.6',
                '134.141.0.0/16' => '172.17.99.99', },
  disable6 => true,
}
```

### DHCP IPv4

When specifying DHCP for IPv4, options include metric, preferred hostname, lease time, and vendor and client strings.

Examples:
```puppet
class { 'net-interface':
  ifname   => 'eth0',
  dhcp4    => {},  # Use DHCPv4 - no extra options
  disable6 => true,
}
```

```puppet
class { 'net-interface':
  ifname   => 'eth0',
  dhcp4    => { hostname => 'hal9000',
                leasetime => 3600, },
  disable6 => true,
}
```

### Disabled IPv4

If IPv4 is set as "disabled", the v4 address family is left unconfigured.
If both address families are set "disabled", the interface as a whole is left administratively down.

```puppet
class { 'net-interface':
  ifname   => 'eth0',
  disable4 => true,
  disable6 => true,
}
```

### Static IPv6

For static IPv6 configuration, specify at least one address/mask to assign. You can optionally specify default gateway or MTU.

The ```routes6``` parameter can be used to specify a list of static routes and
their next-hops to be added when the interface is brought up.

Examples:
```puppet
class { 'net-interface':
  ifname  => 'eth0',
  dhcp4   => {},
  static6 => { addrs => [ '2002:c000:203::1/64',
               gateway => '2002:c000:203::ff', },
}
```

```puppet
class { 'net-interface':
  ifname   => 'eth0',
  static6  => { addrs     => [ '2605:2700:0:3::4444:630e/64',
                               '2605:2700:1:f00d::1/64',
                               '2605:2700:1:f00d::beef/64', ],
                gateway   => '2605:2700:0:3::1',
                mtu       => 2048,
              },
  routes6  => { '6:7:8::9/32' => '2605:2700:0:3::1',
                'a:b:c::d:e:f/93' => '2605:2700:0:3::1', },
  disable4 => true,
}
```

### DHCP IPv6

This is Stateful DHCPv6.  When specifying, options include preferred hostname, lease time, and vendor and client strings.

Examples:
```puppet
class { 'net-interface':
  ifname   => 'mgmt',
  disable4 => true,
  dhcp6    => {},  # Use DHCPv6 - no extra options
}
```

```puppet
class { 'net-interface':
  ifname => 'eth0',
  dhcp6  => { hostname  => 'foo-bar',
              leasetime => 7200, },
}
```

### Disabled IPv6

If IPv6 is set as "disabled", the v6 address family is left unconfigured. This does **not** prevent the usual link-local address from being assigned! So, an interface with v6 "disabled" will likely still have a v6 address in the end. Unless...

If both address families are set "disabled", the interface as a whole is left administratively down.

```puppet
class { 'net-interface':
  ifname   => 'eth0',
  disable4 => true,
  disable6 => true,
}
```

## Reference

Note that several of the high-level parameters are hashes with certain keys supported as outlined.

### Parameters

* ```ifname``` - (string) interface name (mandatory)
* ```dhcp4``` - (hash) use DHCP method for IPv4 address family; valid option keys for "key => value" pairs:
    * ```client``` - (string) client identifier
    * ```hostname``` - (string) requested hostname
    * ```leasetime``` - (int) preferred lease time in seconds
    * ```metric``` - (int) metric for added routes
    * ```vendor``` - (string) vendor class identifier
* ```disable4``` - (bool) disable IPv4 address family (default: false) - as a boolean, be sure to pass ```true``` not the string ```'true'```
* ```static4``` - (hash) use static address assignment for IPv4 address family; valid option keys for "key => value" pairs:
    * ```addrs``` - (string list) address/maskbits ('A.B.C.D/M') strings to assign to interface (mandatory at least one)
    * ```gateway``` - (string) default gateway ('A.B.C.D')
    * ```metric``` - (int) metric for added routes
    * ```mtu``` - (int) max transmissable unit size
* ```routes4``` - (hash list) a list of "route_prefix => next_hop" ('A.B.C.0/24' => 'W.X.Y.Z') pairs defining additional IPv4 static routes to be set
* ```dhcp6``` - (hash) use DHCP method for IPv6 address family; valid option keys for "key => value" pairs:
    * ```client``` - (string) client identifier
    * ```hostname``` - (string) requested hostname
    * ```leasetime``` - (int) preferred lease time in seconds
    * ```vendor``` - (string) vendor class identifier
* ```disable6``` - (bool) disable IPv6 address family (default: false) - as a boolean, be sure to pass ```true``` not the string ```'true'```
* ```static6``` - (hash) use static address assignment for IPv6 address family; valid option keys for "key => value" pairs:
    * ```addrs``` - (string list) address/maskbits ('AA:BB::0099/M') strings to assign to interface (mandatory at least one)
    * ```gateway``` - (string) default gateway ('AA:BB::0C:0D')
    * ```mtu``` - (int) max transmissable unit size
* ```routes6``` - (hash list) a list of "route_prefix => next_hop" ('AA:BB::9:0/64' => '11::22:03:56') pairs defining additional IPv6 static routes to be set

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.


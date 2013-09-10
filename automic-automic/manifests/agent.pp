# == Class: agent
#
# Full description of class agent here.
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
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { agent:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <kdh@automic.com>
#
# === Copyright
#
# Copyright 2013 Automic Software Inc.
#

class automic::agent {

  case $::architecture {
    /i(.{1})86/: { $file_suffix = 'i3' }
    /x(.*)64/: { $file_suffix = 'x6' }
    /ia(.*)64/: { $file_suffix = 'i6' }
    default: { fail("Unrecognized or unsupported CPU architecture: $::architecture") }
  }

  $ostype = $automic::params::ostype

  if $ostype == 'unix' {
    include automic::agent::agent_unix
  } elsif $ostype == 'windows' {
    include automic::agent::agent_windows
  } else {
    fail("Unrecognized or unsupported operating system: $::operatingsystem")
  }  
  
}

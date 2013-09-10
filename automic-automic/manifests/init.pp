# == Class: automic
#
# Full description of class automic here.
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
#  class { automic:
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
class automic (
  $path                           = $automic::params::path,
  $cp                             = $automic::params::cp,  
  $port                           = $automic::params::port,
  $agentname                      = $automic::params::agentname,
  $systemname                     = $automic::params::systemname,
  $license_class                  = $automic::params::license,
  $path                           = $automic::params::path,
  $user                           = $automic::params::user,
  $servicemanager_autostart       = $automic::params::servicemanager_autostart,
  $servicemanager_autostart_delay = $automic::params::servicemanager_autostart_delay,
  $servicemanager_port            = $automic::params::servicemanager_port,
  $servicemanager_path            = $automic::params::servicemanager_path,
  $servicemanager_path_dialog     = $automic::params::servicemanager_path_dialog,
  $servicemanager_phrase          = $automic::params::servicemanager_phrase,
  $servicemanager_smc_file        = $automic::params::servicemanager_smc_file,
  $servicemanager_smd_file        = $automic::params::servicemanager_smd_file,
) inherits automic::params {
  # installs Automic Agent and Service Manager
  include automic::agent
  include automic::servicemanager
}

#
#
class automic::params {
  
  $osf = downcase($::osfamily)

  $ostype = $osf ? {
    /debian|redhat|rhel|fedora|freebsd|arch|suse/ => 'unix',
    'windows'                                     => 'windows',
    default                                       => 'unknown'
  }

  $cp = '192.168.44.45'  
  $port = 2300
  $agentname = $::fqdn
  $systemname = UC4
  $license_class = 1
  $path = $ostype ? {
    'unix' => '/opt/uc4/agent',
    'windows' => "C:\\uc4\\Agents\\windows",
  }
  $user = 'uc4'
  $servicemanager_autostart = "yes"
  $servicemanager_autostart_delay = 0
  $servicemanager_port = 8871
  $servicemanager_path = $ostype ? {
    'unix' => '/opt/uc4/smgr',
    'windows' => "C:\\uc4\\ServiceManager",
  }
  $servicemanager_path_dialog = undef
  if $ostype == 'windows' { $servicemanager_path_dialog = "C:\\uc4\\ServiceManagerDialog" }

  $servicemanager_phrase = 'UC4'
  $servicemanager_smc_file = $ostype ? {
    'unix' => "${servicemanager_path}/bin/uc4.smc",
    'windows' => "${servicemanager_path}\\bin\\UC4.smc",
  }
  $servicemanager_smd_file = $ostype ? {
    'unix' => "${servicemanager_path}/bin/uc4.smd",
    'windows' => "${servicemanager_path}\\bin\\UC4.smd",
  }
}

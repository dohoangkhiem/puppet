#
#

class automic::servicemanager::servicemanager_windows {
  $file_suffix = $automic::servicemanager::file_suffix
  # cache directory to store temporary stuffs
  $cache_path = "C:/temp"

  $service_name = "Automic Windows-Agent"

  file { "cache_dir": 
    ensure => directory,
    path => $cache_path,
  }

  file { "smgr_pkg":
    source => "puppet:///modules/automic/windows/ucsmgrw${file_suffix}.zip",
    path => "${cache_path}/automic_smgr.zip",
    ensure => file,
    require => File["cache_dir"],
  }

  # copy ARATools to temp directory
  file { "temp_aratools":
    source => "puppet:///modules/automic/ARATools.jar",
    ensure => present,
    path => "${cache_path}/ARATools.jar",
    require => File["cache_dir"],
  } 

  # create directory tree
  exec { "create_smgr_dir":
    command => "cmd.exe /c mkdir ${automic::servicemanager_path}",
    path => $::path,
  }
  
  # check target location
  file { "smgr_dir": 
    ensure => directory,
    path => $automic::servicemanager_path,
    require => Exec["create_smgr_dir"],
  }

  # extract to target
  exec { "extract_smgr_package":
    cwd => $cache_path,
    creates => "${automic::servicemanager_path}/bin/ucybsmgr",
    command => "cmd.exe /c java -jar ARATools.jar automic_smgr.zip $automic::servicemanager_path",
    path => $::path,
    require => [ File["agent_pkg"], File["agent_dir"], File["temp_aratools"] ],
  }

  file { "ini_file":  
    ensure => file,
    path => "${automic::servicemanager_path}/bin/ucybsmgr.ini",
    content => template('automic/windows/ucybsmgr.ini.erb'),
    require => Exec["extract_smgr_package"],
  }

  # templating SMD, SMC files
  file { "smd_file":
    ensure => file,
    path => $automic::servicemanager_smd_file,
    content => template('automic/windows/uc4.smd.erb'),
    before => Exec["install_service"],
  }

  if $automic::servicemanager_autostart == "yes" {
    file { "smc_file":
      ensure => file,
      path => $automic::servicemanager_smc_file,
      content => template('automic/uc4.smc.erb'),
      before => Exec["install_service"],
    }
  }

  # execute service manager to install to Windows Service
  exec { "install_service":
    cwd => "${automic::servicemanager_path}/bin",
    command => "${automic::servicemanager_path}/bin/ucybsmgr.exe -install ${automic::servicemanager_phrase} -i${automic::servicemanager_path}/bin/ucybsmgr.ini",
    require => [ Exec["extract_smgr_package"], File["ini_file"] ],
  }

  # enable & start service
  service { "UC4.ServiceManager.${automic::servicemanager_phrase}":
    ensure => 'running',
    enable => true,
    require => Exec["install_service"],
  }

  # install Service Manager Dialog
  file { "smd_pkg":
    ensure => file,
    source "puppet:///modules/automic/windows/ucsmdw#{file_suffix}.zip",
    path => "${cache_path}/automic_smd.zip",
    require => File["cache_dir"],
  }

  exec { "create_smd_dir":
    command => "cmd.exe /c mkdir ${automic::servicemanager_path_dialog}",
    path => $::path,
  }
  
  # check target location
  file { "smd_dir": 
    ensure => directory,
    path => $automic::servicemanager_path_dialog,
    require => Exec["create_smd_dir"],
  }

  # extract service manager dialog
  exec { "extract_smd_pkg":
    cwd => $cache_path,
    command => "cmd.exe /c java -jar ARATools.jar automic_smd.zip $automic::servicemanager_path_dialog",
    creates => "${automic::servicemanager_path_dialog}/bin/UCYBSMCl.exe",
    require => [ File["smd_pkg"], File["smd_dir"], File["temp_aratools"] ],
  }

  # configure Powershell (!)
  exec { "config-powershell"{
    command => "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Unrestricted -scope CurrentUser",   
  }

  # invoke UCYBSMCl to start UC4 Agent  
  unless $automic::servicemanager_autostart == "yes" {
    exec { "start_agent":
      cwd => "${automic::servicemanager_path_dialog}/bin",
      command => "${automic::servicemanager_path_dialog}/bin/UCYBSMCl.exe -c START_PROCESS -h ${::fqdn} -n ${automic::servicemanager_phrase} -s \"${service_name}\"",
      require => [ Service["UC4.ServiceManager.${automic::servicemanager_phrase}"], Exec["extract_smd_pkg"] ],
    }
  }

}

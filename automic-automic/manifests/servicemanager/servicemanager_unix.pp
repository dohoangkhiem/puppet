#
#

class automic::servicemanager::servicemanager_unix {
  
  require automic::agent::agent_unix

  $file_suffix = $automic::servicemanager::file_suffix
  # cache directory to store temporary stuffs
  $cache_path = "/tmp"

  $service_name = "Automic Unix-Agent"
  
  # make copy of service manager package
  file { "smgr_pkg":
    source => "puppet:///modules/automic/unix/ucsmgrl${file_suffix}.tar.gz",
    path => "${cache_path}/automic_smgr.tar.gz",
    ensure => file,
  }

  # create directory tree
  exec { "create_smgr_dir":
    command => "/bin/mkdir -p $automic::servicemanager_path",
  }
  
  # check target location
  file { "smgr_dir": 
    ensure => directory,
    path => $automic::servicemanager_path,
    mode => 0755,
    owner => 'root',
    group => 'root',
    recurse => true,
    require => Exec["create_smgr_dir"],
  }

  # extract service manager stuffs
  exec { "extract_smgr_package":
    cwd => $cache_path,
    creates => "${automic::servicemanager_path}/bin/ucybsmgr",
    command => "/bin/tar xzvf automic_smgr.tar.gz -C ${automic::servicemanager_path} && /bin/chown -R root:root ${automic::servicemanager_path}",
    require => [ File["smgr_pkg"], File["smgr_dir"] ],
  }

  # populate configuration files
  file { "ini_file":  
    ensure => file,
    path => "${automic::servicemanager_path}/bin/ucybsmgr.ini",
    content => template('automic/unix/ucybsmgr.ini.erb'),
    mode => 0644,
    require => Exec["extract_smgr_package"],
  }

  # templating SMD, SMC files
  file { "smd_file":
    ensure => file,
    path => $automic::servicemanager_smd_file,
    mode => 0644,
    content => template('automic/unix/uc4.smd.erb'),
    require => Exec["extract_smgr_package"],
  }

  if $automic::servicemanager_autostart == "yes" {
    file { "smc_file":
      ensure => file,
      path => $automic::servicemanager_smc_file,
      mode => 0644,
      content => template('automic/uc4.smc.erb'),
      require => Exec["extract_smgr_package"],
      before => Exec["start_service"]
    }
  }

  # start Automic service manager
  exec { "start_service":
    cwd => "${automic::servicemanager_path}/bin",
    command => "nohup ./ucybsmgr -iucybsmgr.ini '${automic::servicemanager_phrase}' &",
    require => [ File["ini_file"], File["smd_file"] ],
  }

  unless $automic::servicemanager_autostart == "yes" {
    # start Automic agent
    exec { "start_agent":
      cwd => "${automic::servicemanager_path}/bin",
      command => "./ucybsmcl -c START_PROCESS -h ${::fqdn}:${automic::servicemanager_port} -n ${automic::servicemanager_phrase} -s \"${service_name}\"",
      require => Exec["start_service"],
      onlyif => "/bin/sleep 5",
    }
  }

  info("Automic Service Manager installation finished succesfully")
}

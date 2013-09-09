#
#

class automic::servicemanager::servicemanager_unix (
  $file_suffix = $automic::servicemanager::file_suffix
) inherits automic::servicemanager {
  
  # cache directory to store temporary stuffs
  $cache_path = "/tmp"
  
  # install service manager package
  file { "smgr_pkg":
    source => "puppet:///modules/automic/ucsmgrl${file_suffix}.tar.gz",
    path => "${cache_path}/automic_smgr.tar.gz"
    ensure => file,
  }

  # check target location
  file { "smgr_dir": 
    ensure => directory,
    path => ["/opt/uc4", $automic::servicemanager_path],
    mode => 0755,
    owner => 'root',
    group => 'root',
    recurse => true
  }

  # extract service manager stuffs
  exec { "extract_smgr_package":
    cwd => $cache_path,
    creates => "${automic::servicemanager_path}/bin/ucybsmgr",
    command => "/bin/tar xzvf automic_smgr.tar.gz -C ${automic::servicemanager_path} && /bin/chown -R root:root ${automic::servicemanager_path}",
    require => [ File["smgr_pkg"], File["smgr_dir"] ],
  }

  # populate configuration files
  file { "${automic::servicemanager_path}/bin/ucybsmgr.ini":  
    ensure => file,
    content => template('automic/ucybsmgr.ini.erb'),
    mode => 0644,
    require => Exec["extract_smgr_package"],
  }

  # templating SMD, SMC files
  file { "smd_file":
    ensure => file,
    path => $automic::servicemanager_smd_file,
    mode => 0644,
    content => template('automic/uc4.smd.erb'),
  }

  file { "smc_file":
    ensure => file,
    path => $automic::servicemanager_smc_file,
    mode => 0644,
    content => template('automic/uc4.smc.erb'),
  }

  # start Automic service manager
  exec { "start-service":
    
  }

  # start Automic agent
  exec { "start-agent":

  }

  info("Automic Service Manager installation finished succesfully")
}

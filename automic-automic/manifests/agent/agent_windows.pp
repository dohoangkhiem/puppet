#
#

class automic::agent::agent_windows {

  # cache directory to store temporary stuffs
  $cache_path = "C:/temp"

  file { "cache_dir": 
    ensure => directory,
    path => $cache_path,
  }

  # copy Automic agent package
  file { "agent_pkg":
    source => "puppet:///modules/automic/windows/uc4agent.zip",
    path => "${cache_path}/automic_agent.zip",
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

  # check target agent path
  exec { "create_agent_dir":
    command => "cmd.exe /c mkdir ${automic::path}",
    path => $::path,
  }

  file { "agent_dir": 
    ensure => directory,
    path => $automic::path,
    require => Exec["create_agent_dir"],
  }

  # extract to target
  exec { "extract_agent_package":
    cwd => $cache_path,
    creates => "${automic::path}/bin/uc.msl",
    command => "cmd.exe /c java -jar ARATools.jar automic_agent.zip $automic::path",
    path => $::path,
    require => [ File["agent_pkg"], File["agent_dir"], File["temp_aratools"] ],
  }

  # templating
  file { "${automic::path}/bin/ucxjl${file_suffix}.ini":
    ensure => file,
    content => template('automic/unix/ucxjlxx.ini.erb'),
    mode => 0644, 
    require => Exec['extract_agent_package'],
  }

  # copy ARATools.jar to destination path
  file { "${automic::path}/bin/ARATools.jar":
    source => "puppet:///modules/automic/ARATools.jar",
    ensure => present,
    require => [ Exec["extract_agent_package"] ]
  }    

  info("Automic agent installation finished successfully!")

}

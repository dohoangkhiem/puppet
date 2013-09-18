#
#

class automic::agent::agent_windows {
  $file_suffix = $automic::agent::file_suffix
  # cache directory to store temporary stuffs
  $cache_path = "C:/temp"

  file { "cache_dir": 
    ensure => directory,
    path => $cache_path,
  }

  # copy Automic agent package
  #file { "agent_pkg":
  #  source => "puppet:///modules/automic/windows/ucagentw${file_suffix}.zip",
  #  path => "${cache_path}/automic_agent.zip",
  #  ensure => file,
  #  require => File["cache_dir"],
  #}

  # check target agent path
  exec { "create_agent_dir":
    command => "cmd.exe /c mkdir ${automic::path}",
    path => $::path,
    unless => "cmd.exe /c if exist ${automic::path} ( exit 0 ) else ( exit 1 )",
  }

  #file { "agent_dir": 
  # ensure => directory,
  #  path => $automic::path,
  #  require => Exec["create_agent_dir"],
  #}

  # copy agent to target
  file { "copy_agent_package":
    path => $automic::path,
    source => "puppet:///modules/automic/windows/ucagentw${file_suffix}",
    ensure => directory,
    recurse => true,
    require => Exec["create_agent_dir"],
    mode => 0755,
  }

  # templating
  file { "${automic::path}/bin/ucxjw${file_suffix}.ini":
    ensure => file,
    content => template("automic/windows/ucxjw${file_suffix}.ini.erb"),
    require => File['copy_agent_package'],
  }

  # copy ARATools.jar to destination path
  file { "${automic::path}/bin/ARATools.jar":
    source => "puppet:///modules/automic/ARATools.jar",
    ensure => present,
    require => File["copy_agent_package"],
  }    

  info("Automic agent installation finished successfully!")

}

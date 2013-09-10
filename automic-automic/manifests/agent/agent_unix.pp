#
#

class automic::agent::agent_unix {
  $file_suffix = $automic::agent::file_suffix
  # cache directory to store temporary stuffs
  $cache_path = "/tmp"
  
  # copy Automic agent package
  file { "agent_pkg":
    source => "puppet:///modules/automic/unix/ucagentl${file_suffix}.tar.gz",
    path => "${cache_path}/automic_agent.tar.gz",
    ensure => file,
  }

  # check target location
  #file { ["/opt/uc4", $automic::path]: 
  #  ensure => directory,
  #  mode => 0755,
  #  owner => 'root',
  #  group => 'root',
  #  recurse => true
  #}

  exec { "create_agent_dir":
    command => "/bin/mkdir -p ${automic::path}"
  }

  file { "agent_dir": 
    ensure => directory,
    path => $automic::path,
    mode => 0755,
    owner => 'root',
    group => 'root',
    recurse => true,
    require => Exec["create_agent_dir"],
  }

  # extract to target
  exec { "extract_agent_package":
    cwd => $cache_path,
    creates => "${automic::path}/bin/ucx.msl",
    command => "/bin/tar xzvf automic_agent.tar.gz -C ${automic::path} && /bin/chown -R root:root ${automic::path}",
    require => [ File["agent_pkg"], File["agent_dir"] ],
  }
 
  # templating
  file { "${automic::path}/bin/ucxjl${file_suffix}.ini":
    ensure => file,
    content => template('automic/unix/ucxjlxx.ini.erb'),
    mode => 0644, 
    require => Exec['extract_agent_package'],
  }

  # copy ARATools.jar
  file { "${automic::path}/bin/ARATools.jar":
    source => "puppet:///modules/automic/ARATools.jar",
    ensure => present,
    require => [ Exec["extract_agent_package"] ]
  }    

  info("Automic agent installation finished successfully!")
}

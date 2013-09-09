#
#

class automic::agent::unix_agent (
  $file_suffix = $automic::agent::file_suffix
) inherits automic::agent {
  # cache directory to store temporary stuffs
  $cache_path = "/tmp"
  
  # copy Automic agent package
  file { "agent_pkg":
    source => "puppet:///modules/automic/ucagentl${file_suffix}.tar.gz",
    path => "${cache_path}/automic_agent.tar.gz",
    ensure => file,
  }

  # check target location
  file { "agent_dir": 
    ensure => directory,
    path => ["/opt/uc4", $automic::path],
    mode => 0755,
    owner => 'root',
    group => 'root',
    recurse => true
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
    content => template('automic/ucxjlxx.ini.erb'),
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

#
#

class automic::servicemanager {
  require automic::agent
  case $::architecture {
    /i(.{1})86/: { $file_suffix = 'i3' }
    /x(.*)64/: { $file_suffix = 'x6' }
    /ia(.*)64/: { $file_suffix = 'i6' }
    default: { fail("Unrecognized or unsupported CPU architecture: $::architecture") }
  }

  $ostype = $automic::params::ostype

  if $ostype == 'unix' {
    include automic::servicemanager::servicemanager_unix
  } elsif $ostype == 'windows' {
    include automic::servicemanager::servicemanager_windows
  } else {
    fail("Unrecognized or unsupported operating system: $::operatingsystem")
  }  
}

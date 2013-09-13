# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation errors
# and view a log of events) or by fully applying the test in a virtual environment
# (to compare the resulting system state to the desired state).
#
# Learn more about module testing here: http://docs.puppetlabs.com/guides/tests_smoke.html
#

# by default, this will install agent & service manager on agent node
include automic

# create deployment target
automic_deployment_target { $::fqdn:
  folder              => 'D_X1',
  owner               => 'admin',
  type                => 'Tomcat',
  environment         => 'Test',
  agent               => upcase($::fqdn),
  connection          => { 'url' => 'http://172.16.36.12/4low', 'username' => 'admin', 'password' => 'bond' },
  properties          => { 'home_directory' => '/opt/tomcat', 'port' => 8080, 'host' => 'localhost' },
  dynamic_properties  => { 'myValue' => { 'namespace' => '/my/name/space', 'value' => 'my value', 'type' => 'SingleLineText', 'description' => 'This is my value' }, 
                           'version' => { 'namespace' => '/my/version', 'value' => '1.1.3', 'type' => 'SingleLineText', 'description' => 'The version number'  }  },
  ensure              => present,
}

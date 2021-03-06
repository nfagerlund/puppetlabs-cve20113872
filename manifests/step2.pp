# Class: cve20113872::step2
#
#   This class reconfigures the Puppet Agent to use an intermediate DNS name to
#   contact the Puppet Master.  This name will not be contained in the
#   alternate names erroneously issued to all agents as described in
#   CVE-2011-3872.
#
#   Once an agent successfully applies this class it will not be vulnerable to
#   a man in the middle attack.
#
# Parameters:
#
# Actions:
#
#   * Reconfigure puppet.conf to contact the master on the intermediate DNS name.
#   * Send a HUP signal to the agent to reload itself.
#
# Requires:
#
# Sample Usage:
#
class cve20113872::step2 {
  $module = "cve20113872"

  # pe-puppet or puppet
  cve20113872_validate_re($agent_user, "puppet")
  # pe-puppet or puppet
  cve20113872_validate_re($agent_group, "puppet")
  # Agents vardir.  We'll put scripts in here.
  cve20113872_validate_re($agent_vardir, '^/')

  # Common class is the "main" class
  include "${module}"

  Exec { path => "/opt/puppet/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/csw/bin" }
  File {
    owner   => "${agent_user}",
    group   => "${agent_group}",
    mode    => '0644'
  }

  # We need to figure out the intermediate DNS name.  This should have been
  # written in step1 to persistent storage in the puppet confdir.
  $dns_name_file = inline_template("<%= File.join(Puppet[:vardir], '${module}', 'dns_name') %>")
  $dns_name = inline_template("<%= File.read('${dns_name_file}').chomp rescue '' %>")
  if $dns_name == "" {
    fail("Error: could not read DNS name from file: ${dns_name_file} (This should have been set in step1)")
  }
  exec { "CVE-2011-3872 Use Intermediate DNS Name":
    command => "${agent_vardir}/${module}/bin/reconfigure_server.rb '${agent_config}' '${dns_name}'",
    unless  => "sh -c \"puppet agent --configprint server | grep '^${dns_name}\$'\"",
    require => File["${agent_vardir}/${module}/bin/reconfigure_server.rb"],
    notify  => Exec["CVE-2011-3872 Step2 Reload"],
  }
  exec { "CVE-2011-3872 Step2 Reload":
    command     => "kill -HUP ${agent_pid}",
    refreshonly => true,
  }
}

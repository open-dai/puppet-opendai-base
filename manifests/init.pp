# Class: base
#
# This module manages base
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class base {
  $repo_server = 'yum-repo.cloudlabcsi.eu'

  # we could have the puppet_master info given from cloudstack to the env and thus in fact or created manually so pointing to the
  # central puppet
  # this is a migration temporary issue
  if $::puppet_master == undef {
    $puppet_master = "puppet.${::domain}"
  } else {
    $puppet_master = $::puppet_master
  }

  # role could be taken from cloudstack or from the hostname
  if $::role == undef {
    $role = $::hostname
  } else {
    $role = $::role
  }

  # Includes that apply to all machines
  package {
    curl:
      ensure => present;

    wget:
      ensure => present;

    augeas:
      ensure => present;
  }

  class { '::mcollective':
#    stomp_server         => $puppet_master,
	middleware_hosts     => [$puppet_master],
	middleware_password  => hiera('stomp_passwd', ""),
    psk					 => hiera('mc_security_psk', ""),
	server               => true,
    client               => false,
#    mc_security_provider => 'psk',
#    mc_security_psk      => hiera('mc_security_psk', ""),
#    stomp_port           => 6163,
#    stomp_passwd         => hiera('stomp_passwd', ""),
    factsource          => 'yaml',
  }

  mcollective::plugin { 'puppet':
    package => true,
  }

  mcollective::plugin { 'service':
    package => true,
  }

  mcollective::plugin { 'process':
    package => true,
  }

  package { 'fail2ban': ensure => present, }

  service { 'fail2ban':
    ensure  => running,
    require => Package['fail2ban'],
    before  => Anchor['base::basic'],
  }

  anchor { 'base::basic': }

  group { zabbix:
    ensure  => present,
    require => Anchor['base::basic'],
  }

  user { zabbix:
    ensure     => present,
    managehome => true,
    gid        => 'zabbix',
    require    => Group['zabbix'],
    comment    => 'Zabbix user'
  }

  package { 'zabbix':
    ensure  => present,
    require => User['zabbix'],
  }

  package { 'zabbix-agent':
    ensure  => present,
    require => Package['zabbix'],
  }
  $ZabbixServerIP = hiera('ZabbixServerIP', "")
  notice("zabbix: ${ZabbixServerIP}")

  file { "/etc/zabbix/zabbix_agentd.conf":
    ensure  => "present",
    content => template("base/zabbix_agentd.conf.erb"),
    require => Package['zabbix-agent'],
  }

  file { "/etc/zabbix/zabbix_agent.conf":
    ensure  => "present",
    content => template("base/zabbix_agent.conf.erb"),
    require => Package['zabbix-agent'],
    before  => Anchor['base:end_common'],
  }

  service { 'zabbix-agent': ensure => 'running', }

  anchor { 'base:end_common': }

  #  augeas { "zabbix-agentd-conf":
  #    lens    => "Shellvars.lns",
  #    incl    => "/etc/zabbix/zabbix_agentd.conf",
  #    changes => "set /files/etc/zabbix/zabbix_agentd.conf/Server 10.1.1.102",
  #    require  =>
  #    File['/etc/zabbix/zabbix_agentd.conf'],
  #  }
  # 					  "set /files/etc/zabbix/zabbix_agentd.conf/ServerActive 10.1.1.102",
  # 					  "set /files/etc/zabbix/zabbix_agentd.conf/Hostname test",
  # 					 ]
  # 		  context => "/files/etc/zabbix/zabbix_agentd.conf",

  notice("class base included")
  notice("timezone: ${::timezone}")
  notice("timezone: ${::env}")
  notice("puppetmaster: ${puppet_master}")
  notice("puppetmaster fact: ${::puppet_master}")
  notice("role: ${role}")
  
  # role-specific includes
  case $role {
    'apache'               : {
      class { 'odaiweb':
        repos   => $repo_server,
        require => Anchor['base:end_common'],
      }
    }
    'nginx'                : {
      class { 'odaiproxy': require => Anchor['base:end_common'], }
    }
    'nfs'                  : {
      class { 'odainfs':
        package_url => "${repo_server}",
        require     => Anchor['base:end_common'],
      }
    }
    'jbossvdbmaster'       : {
	  mcollective::plugin { 'apt':
		source => 'puppet:///modules/base/plugins/jboss',
	  }
      class { 'odaijbossmasterbb':
        package_url             => "${repo_server}",
        bind_address            => $::ipaddress,
        bind_address_management => $::ipaddress,
        bind_address_unsecure   => $::ipaddress,
        deploy_dir              => "/opt/jboss",
        mode                    => "domain",
        admin_user              => 'admin',
        admin_user_password     => 'opendaiadmin1!',
        require                 => Anchor['base:end_common'],
      }
    }
    'jbossappmaster'       : {
      class { 'odaijbossmaster':
        package_url             => "${repo_server}",
        bind_address            => $::ipaddress,
        bind_address_management => $::ipaddress,
        bind_address_unsecure   => $::ipaddress,
        deploy_dir              => "/opt/jboss",
        mode                    => "domain",
        admin_user              => 'admin',
        admin_user_password     => 'opendaiadmin1!',
        require                 => Anchor['base:end_common'],
      }
    }
    'jbossvdbslave'        : {
      $vdbmasterIP = get_ip_addr("jbossvdbmaster.$::domain")

      class { 'odaijbossslavebb':
        package_url             => "${repo_server}",
        bind_address            => $::ipaddress,
        bind_address_management => $::ipaddress,
        bind_address_unsecure   => $::ipaddress,
        deploy_dir              => "/opt/jboss",
        mode                    => "domain",
        admin_user              => $::hostname,
        admin_user_password     => 'opendaiadmin',
        master_ip               => $vdbmasterIP,
        require                 => Anchor['base:end_common'],
      }
    }
    'jbossappslave'        : {
      $appmasterIP = get_ip_addr("jbossappmaster.$::domain")

      class { 'odaijbossslave':
        package_url             => "${repo_server}",
        bind_address            => $::ipaddress,
        bind_address_management => $::ipaddress,
        bind_address_unsecure   => $::ipaddress,
        deploy_dir              => "/opt/jboss",
        mode                    => "domain",
        admin_user              => $::hostname,
        admin_user_password     => 'opendaiadmin',
        master_ip               => $appmasterIP,
        require                 => Anchor['base:end_common'],
      }
    }
    'wso2mysql'            : {
      class { 'odaisoamysql': }
    }
    'wso2api'              : {
      class { 'odaiapiman':
        require     => Anchor['base:end_common'],
        repo_server => $repo_server
      }
    }
    'wso2greg'             : {
      class { 'odaigreg':
        repo_server => $repo_server,
        require     => Anchor['base:end_common'],
      }
    }
    'wso2esb'              : {
      class { 'odaiesb':
        require     => Anchor['base:end_common'],
        repo_server => $repo_server
      }
    }
    'wso2bam'              : {
      class { 'odaibam':
        require     => Anchor['base:end_common'],
        repo_server => $repo_server
      }
    }
    'wso2bps'              : {
      class { 'odaibps':
        require     => Anchor['base:end_common'],
        repo_server => $repo_server
      }
    }
    'zabbix'               : {
      #            include otherrole
      class { 'odaizabbix':
        timezone => $::env,
        require  => Anchor['base:end_common'],
        java_url => "${repo_server}",
      }
    }
    'zabbixproxy'          : {
      #            include otherrole
      class { 'odaizabbixproxy':
        zabbix_server => '194.116.110.93',
        version => '2.2.2',
        require       => Anchor['base:end_common'],
      #        version => "${repo_server}",
      }
    }
    'backup'               : {
      class { 'rdiff-backup::server': require => Anchor['base:end_common'], }
    }
    default                : {
    }
  }
}

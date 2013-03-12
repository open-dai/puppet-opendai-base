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

  # Includes that apply to all machines
  package {
    curl:
      ensure => present;

    wget:
      ensure => present;

    augeas:
      ensure => present;
  }

  class { 'mcollective':
    stomp_server         => "${::puppet_master}",
    server               => true,
    client               => false,
    mc_security_provider => 'psk',
    mc_security_psk      => 'csi$mcollective',
    stomp_port           => 6163,
    stomp_passwd         => 'csi$stomp',
    fact_source          => 'yaml',
  }

  /*
   * yumrepo { "kbsingh-CentOS-Extras":
   * baseurl  => "http://centos.karan.org/kbsingh-CentOS-Extras.repo",
   * descr    => "kbsingh-CentOS-Extras",
   * enabled  => 0,
   * gpgcheck => 0,
   *}
   */
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
    #    source   => "http://${puppet_master}/zabbix-2.0.2-1.el6.x86_64.rpm",
    #    provider => 'rpm',
    require => User['zabbix'],
  }

  package { 'zabbix-agent':
    ensure  => present,
    #    source   => "http://${puppet_master}/zabbix-agent-2.0.2-1.el6.x86_64.rpm",
    #    provider => 'rpm',
    require => Package['zabbix'],
  }
  $ZabbixServer = "zabbix.$::domain"
  $ZabbixServerIP = get_ip_addr($ZabbixServer)
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
  notice("timezone: ${timezone}")
  notice("timezone: ${::env}")
  notice("puppetmaster: ${puppet_master}")
  notice("puppetmaster: ${::puppet_master}")

  # role-specific includes
  case $role {
    'apache'               : {
      #            include somerole
      #      apache_httpd { 'prefork': modules => ['mime'] }

      #            class { 'java':
      #                   distribution => 'jdk',
      #                   version => 'latest',
      #            }
      #      package { 'nodejs':
      #        ensure   => present,
      #        source   => "http://${puppet_master}/nodejs-0.8.9-1.el6.x86_64.rpm",
      #        provider => 'rpm',
      #      }
      class { 'odaiweb':
        require => Anchor['base:end_common'],
      }
    }
    'nginx'                : {
      class { 'odaiproxy': require => Anchor['base:end_common'], }
    }
    'mongodb'              : {
      package { 'mongodb-server':
        ensure => present,
      #              source   => "http://${puppet_master}/nodejs-0.8.9-1.el6.x86_64.rpm",
      #              provider => 'rpm',
      }
    }
    'foo'                  : {
      #            include somerole
      include apache

      class { 'opendai_java':
        distribution => 'jdk',
        version      => '6u25',
      }

      #     class { 'jbossas':
      #       mirror_url   => "http://${puppet_master}/",
      #       bind_address => $::ipaddress,
      #       dir          => '/opt/jboss',
      #     }
    }
    'jboss-vdb-master'     : {
      class { 'odaijbossmaster':
        package_url             => "${repo_server}",
        bind_address            => $::ipaddress,
        bind_address_management => $::ipaddress,
        bind_address_unsecure   => $::ipaddress,
        deploy_dir              => "/opt/jboss",
        mode                    => "domain",
        admin_user              => 'admin',
        admin_user_password     => 'opendaiadmin',
        require                 => Anchor['base:end_common'],
      }
    }
    'jboss-vdb-master_old' : {
      class { 'opendai_java':
        distribution => 'jdk',
        version      => '6u25',
      }

      class { 'jbossas':
        package_url  => "${puppet_master}",
        bind_address => $::ipaddress,
        deploy_dir   => "/opt/jboss",
        mode         => "domain",
        require      => [Class['opendai_java']],
      }

      jbossas::add_user { 'admin':
        password   => "opendaiadmin",
        deploy_dir => "/opt/jboss",
        mode       => "domain",
        require    => [Class['jbossas']],
      }

      jbossas::add_user { 'gioppo':
        password   => "opendaiadmin",
        deploy_dir => "/opt/jboss",
        mode       => "domain",
        require    => [Class['jbossas']],
      }
      Jbossas::Add_user <<| tag == 'new_vdb_slave' |>>

      notice("now mod interfaces")

      jbossas::set_host_name { 'master-master':
        oldname    => "master",
        newname    => "master",
        deploy_dir => "/opt/jboss",
        require    => [Class['jbossas']],
      }

      notice("now mod interfaces")

      jbossas::mod_host_interface { 'master-public':
        jbhost_name => "master",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      jbossas::mod_host_interface { 'master-management':
        jbhost_name => "master",
        interface   => "management",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      jbossas::mod_host_interface { 'master-unsecure':
        jbhost_name => "master",
        interface   => "unsecure",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      notice("now create server_groups")

      jbossas::add_server_group { 'teiid-server-group':
        profile              => "ha",
        socket_binding_group => "ha-sockets",
        offset               => "0",
        deploy_dir           => "/opt/jboss",
        require              => [Class['jbossas']],
      }
      notice("now create jvm into server_groups")

      jbossas::add_jvm_server_group { 'teiid-server-group':
        heap_size     => "128m",
        max_heap_size => "1024m",
        deploy_dir    => "/opt/jboss",
        require       => [Class['jbossas']],
      }

      notice("now create server")

      jbossas::add_server { 'teiid1':
        jbhost_name  => "master",
        server_group => "teiid-server-group",
        deploy_dir   => "/opt/jboss",
        require      => [Class['jbossas']],
      }

      # ########### Setting info for slaves
      @@jbossas::set_domain_controller { 'jbslave':
        deploy_dir => "/opt/jboss",
        require    => [Class['jbossas']],
        tag        => "domain_controller_jbslave"
      }

    }
    'jboss-vdb-slace'      : {
      # ###########MIND TO CHANGE
      class { 'opendai_java':
        distribution => 'jdk',
        version      => '6u25',
      }

      class { 'jbossas':
        package_url  => "http://${puppet_master}/",
        bind_address => $::ipaddress,
        deploy_dir   => "/opt/jboss",
        mode         => "domain",
        require      => [Class['opendai_java']],
      }

      # 		jbossas::add_user { 'admin':
      # 				password => "opendaiadmin",
      # 				deploy_dir => "/opt/jboss",
      # 				mode => "domain",
      # 				require => [Class['jbossas']],
      # 		}
      # 		jbossas::add_user { 'jbslave':
      # 				password => "opendaiadmin",
      # 				deploy_dir => "/opt/jboss",
      # 				mode => "domain",
      # 				require => [Class['jbossas']],
      # 		}
      # 		Jbossas::Add_user <<| tag == 'new_vdb_slave' |>>
      #
      # 		notice ("now mod interfaces")
      jbossas::set_host_name { 'master-jbslave':
        oldname    => "master",
        newname    => "jbslave",
        deploy_dir => "/opt/jboss",
        require    => [Class['jbossas']],
      }

      notice("now mod interfaces")

      jbossas::mod_host_interface { 'jbslave-public':
        jbhost_name => "jbslave",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      jbossas::mod_host_interface { 'jbslave-management':
        jbhost_name => "jbslave",
        interface   => "management",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      jbossas::mod_host_interface { 'jbslave-unsecure':
        jbhost_name => "jbslave",
        interface   => "unsecure",
        deploy_dir  => "/opt/jboss",
        require     => [Class['jbossas']],
      }

      jbossas::remove_local_controller { 'jbslave':
        deploy_dir => "/opt/jboss",
        require    => [Class['jbossas']],
      }

      # ############# getting info from master
      Jbossas::Set_domain_controller <<| tag == 'domain_controller_jbslave' |>>

      #
      # 		notice ("now create server_groups")
      # 		jbossas::add_server_group { 'teiid-server-group':
      # 				profile => "ha",
      # 				socket_binding_group => "ha-sockets",
      # 				offset => "0",
      # 				deploy_dir => "/opt/jboss",
      # 				require => [Class['jbossas']],
      # 		}
      # 		notice ("now create jvm into server_groups")
      # 		jbossas::add_jvm_server_group { 'teiid-server-group':
      # 				heap_size => "128m",
      # 				max_heap_size => "1024m",
      # 				deploy_dir => "/opt/jboss",
      # 				require => [Class['jbossas']],
      # 		}
      #
      # 		notice ("now create server")
      # 		jbossas::add_server { 'teiid1':
      # 				jbhost_name => "master",
      # 				server_group => "teiid-server-group",
      # 				deploy_dir => "/opt/jboss",
      # 				require => [Class['jbossas']],
      # 		}
    }
    'wso2mysql'            : {
      class { 'odaisoamysql': }
    }
    'mysql'                : {
      #            include otherrole
      class { 'mysql::server':
        config_hash => {
          root_password => 'changeme',
          bind_address  => $::ipaddress,
        }
      }
      Mysql::Db <<| tag == 'new_db' |>>
      notice("mysql server and Db done")

      mysql::db { 'mydatabase':
        user     => 'myapp1',
        password => 'supersecret',
        host     => 'webapp1.puppetlabs.com',
      }
      notice("mydatabase done")
    }
    'otherrole'            : {
      class { 'opendai_java':
        distribution => 'jdk',
        version      => '6u25',
      }
      #            include otherrole
    }
    'wso2api'              : {
      class { 'odaiapiman':
        require     => Anchor['base:end_common'],
        repo_server => $repo_server
      }
    }
    'wso2greg'             : {
      class { 'odaigreg':
        download_site => "http://${repo_server}/",
        require       => Anchor['base:end_common'],
      }
    }
    'wso2esb'              : {
      class { 'odaiesb': require => Anchor['base:end_common'], }
    }
    'wso2bam'              : {
      class { 'odaibam': require => Anchor['base:end_common'], }
    }
    'wso2pbs'              : {
      class { 'odaibps': }
    }
    'apiman_old'           : {
      # REQUIREMENTS
      # Java
      class { 'opendai_java':
        distribution => 'jdk',
        version      => '6u25',
      }

      # ANT
      package { ant: ensure => present; }

      # MAVEN
      exec { download_maven:
        command   => "/usr/bin/curl -v -L --progress-bar -o '/root/apache-maven-3.0.4-bin.tar.gz' 'http://www.apache.org/dist/maven/binaries/apache-maven-3.0.4-bin.tar.gz'",
        creates   => '/root/apache-maven-3.0.4-bin.tar.gz',
        # 		user => 'zabbix',
        logoutput => true,
      # 				require => File[$dist_dir],
      }

      # Extract Maven
      exec { extract_maven:
        command   => "/bin/tar -xzvf '/root/apache-maven-3.0.4-bin.tar.gz'",
        creates   => "/opt/apache-maven-3.0.4",
        cwd       => '/opt',
        # 				user => 'zabbix',
        # 				group => 'zabbix',
        logoutput => true,
        # 		unless => "/usr/bin/test -d '$jbossas::dir'",
        require   => [Exec['download_maven']]
      }

      # 		nano .bashrc
      # 		export M2_HOME=/opt/apache-maven-3.0.4
      #           export PATH=${M2_HOME}/bin:${PATH}
      #
      # Download the Api MAnager distribution ~153MB file
      # $mirror_url = "http://dist.wso2.org/products/api-manager/${apiman::version}/wso2am-${apiman::version}.zip"
      $mirror_url = "http://dist.wso2.org/products/api-manager/1.0.0/wso2am-1.0.0.zip"
      $dist_dir = '/root'
      # $dist_file = "${dist_dir}/wso2am-${apiman::version}.zip"
      $dist_file = "${dist_dir}/wso2am-1.0.0.zip"
      notice "Download URL: $mirror_url"

      exec { download_apiman:
        command   => "/usr/bin/curl -v -L --progress-bar -o '$dist_file' '$mirror_url'",
        creates   => $dist_file,
        unless    => "/usr/bin/test -d '$dist_file'",
        # 		user => 'zabbix',
        logoutput => true,
      # 		require => File[$dist_dir],
      }

      # defnode <NAME> <EXPR> [<VALUE>]
      augeas { "test":
        lens    => "Shellvars.lns",
        incl    => "/root/test",
        changes => "defnode nuovo_nodo /files/root/test/nuovo_nodo prova",
      }

      augeas { "testx":
        lens    => "Xml.lns",
        incl    => "/root/testx.xml",
        context => "/files/root/testx.xml",
        changes => [
          "set /node valore_nuovo-nodo",
          # 		"defnode nuovo_nodo /files/root/testx/node/nuovo_nodo prova",
          # 		"defnode nuovo_nodo1 /files/root/testx/node/nuovo_nodo1 prova",
          # 		"ins mezzo after /files/root/testx/node/nuovo_nodo",
          # 		"ins ultimo after /files/root/testx/node/nuovo_nodo1",
          # 		"ins figlioo after /files/root/testx/node/nuovo_nodo",
          # 		"set /files/root/testx/node/nuovo_nodo valore_nuovo-nodo",
          # 		"defnode @attri /files/root/testx/node/nuovo_nodo1/@attri provaatt",
          ],
      }

      # unzip
      # unzip wso2am-1.0.0.zip
    }
    'zabbix'               : {
      #            include otherrole
      class { 'odaizabbix':
        timezone => $::env,
        require  => Anchor['base:end_common'],
        java_url => "${repo_server}",
      }
    }
    'backup'               : {
      class { 'rdiff-backup::server': require => Anchor['base:end_common'], }
    }
    'moodle'               : {
      class { 'mysql': }

      class { 'mysql::server':
        config_hash => {
          'root_password' => 'password'
        }
        ,
        require     => Class['mysql']
      }

      # Database <<| tag == 'moodle_db' |>>
      # Database_user <<| tag == 'moodle_db' |>>
      Mysql::Db <<| tag == 'moodle_db' |>>

      class { 'apache': require => Class['mysql'] }

      class { 'apache::mod::php': }

      package { [php-mysql, php-gd, php-intl, php-mbstring, php-soap, php-xml, php-xmlrpc, sudo]:
        ensure  => present,
        require => Class['apache::mod::php']
      }

      package { zip: ensure => present; }

      class { 'moodle': tarball_url => 'http://sourceforge.net/projects/moodle/files/Moodle/stable23/moodle-2.3.3.tgz', }

      class { 'libreoffice':
        version => '3.6.4',
        ui      => 'headless'
      }

    }
    default                : {
      #        	include apache_httpd
      #        	apache_httpd { 'prefork':
      #        		modules => [ 'mime' ]
      #        	}
    }
  }
}

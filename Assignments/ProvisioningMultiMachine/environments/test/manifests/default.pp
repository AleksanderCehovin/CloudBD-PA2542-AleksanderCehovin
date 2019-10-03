#Common to all nodes
Exec{
	path => ['/bin','/usr/bin'],
}
exec { 'update':
	command => 'apt-get update > /tmp/aptupdate.output.txt',
}

#Database password
$mysql_password = "1337"

define writeProxyAndRedisIpToHomedir() {
	file {  '/home/vagrant/redis_static_ip.conf':
		content => $redis_static_ip,
	}
	file {  '/vagrant/hosts/redis_static_ip.conf':
		content => $redis_static_ip,
	}	
	exec {  'copy-proxy-to-homedir':
		path => ['/bin', '/usr/bin'],
		command => "sudo cp  /vagrant/hosts/proxy_dynamic_ip.conf /home/vagrant/",
	}	
}

node default {

}

node 'appserver' {
	writeProxyAndRedisIpToHomedir{'setIps':}			
	package { 'curl': 
		ensure => present,
		require => Exec['update'],
	}
	exec { 'nodeprepare':
		command => 'curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - > /tmp/nodeprepare.output.txt',
		require=>Exec['update'],
	}
	package { 'nodejs':
		ensure => present,
		require => Exec['nodeprepare'],
	}	
}

#The password set part does not work, since mysql uses an authentication plugin that does not care about passwords.
#Keeping this part anyway for future reference.
node 'dbserver' {
	writeProxyAndRedisIpToHomedir{'setIps':}		
	package{'mysql-server':
		ensure=>installed,
#		require=>Exec['copy-proxy-to-homedir'],
	}
	service {'mysql':
		enable=>true,
		ensure=>running,
		require=>Package['mysql-server'],
	}		
	file { '/var/lib/mysql/my.cnf':
		owner => "mysql", group => "mysql",
		ensure=> 'present',
		source => 'puppet:///modules/mysql/my.cnf',
		notify => Service['mysql'],
		require => Package['mysql-server'],
	}
	file { '/etc/mysql/my.cnf':
		require => File['/var/lib/mysql/my.cnf'],
		ensure => '/var/lib/mysql/my.cnf',
	}
	exec { 'set-mysql-password':
		unless => "mysqladmin -uroot -p$mysql_password status",
		path => ['/bin', '/usr/bin'],
		command => "mysqladmin -uroot password $mysql_password",
		require => Package['mysql-server'],
	}
}

node 'web' {
	writeProxyAndRedisIpToHomedir{'setIps':}		
	package { 'nginx':
		ensure => installed,
		require=>Exec['copy-proxy-to-homedir'],
	}
	service {'nginx':
		ensure => running,
		require => Package['nginx'],
	}
}

node 'redis' {
	package { 'redis':
		ensure => installed,
	}
	service {'redis-server':
		ensure => running,
		require => Package['redis'],
	}
}



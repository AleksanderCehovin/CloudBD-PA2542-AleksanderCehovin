#Common to all nodes
Exec{
	path => ['/bin','/usr/bin'],
}
exec { 'update':
	command => 'apt-get update > /tmp/aptupdate.output.txt',
}

node default {

}
#Database password
$mysql_password = "1337"

node 'appserver' {
	file {  '/tmp/hello':
		content => "Hello, appserver!\n",
	}
	package { 'curl': 
		ensure => present,
		require => Exec['update'],
	}
	exec { 'nodeprepare':
		command => 'curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - > /tmp/nodeprepare.output.txt',
		require => Package['curl'],
	}
	package { 'nodejs':
		ensure => present,
		require => Exec['nodeprepare'],
	}	
}

#The password set part does not work, since mysql uses an authentication plugin that does not care about passwords.
#Keeping this part anyway for future reference.
node 'dbserver' {
	file {  '/tmp/hello':
		content => "Hello, dbserver! Need to figure our how to install mysql\n",
	}
	package{'mysql-server':
		ensure=>installed,
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
	file {  '/tmp/hello':
		content => "Hello, web! Need to figure our how to install nginx\n",
	}
	package { 'nginx':
		ensure => installed,
	}
	service {'nginx':
		ensure => running,
		require => Package['nginx'],
	}
}


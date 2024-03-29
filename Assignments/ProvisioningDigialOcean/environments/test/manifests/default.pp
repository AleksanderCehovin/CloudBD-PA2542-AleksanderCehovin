#Common to all nodes
Exec{
	path => ['/bin','/usr/bin'],
}
exec { 'update':
	command => 'apt-get update > /tmp/aptupdate.output.txt',
}

node default {

}

node 'appserver' {
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

#This part used to have a part that set a passworkd, but it did not work, since mysql uses an authentication plugin that 
#does not care about passwords. Relying on sudo for accessing database information seems to be a better solution anyway.
node 'dbserver' {
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

}




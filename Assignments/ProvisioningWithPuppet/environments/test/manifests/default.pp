Exec{
	path => ['/bin','/usr/bin'],
}

exec { 'update':
	command => 'apt-get update > /tmp/aptupdate.output.txt',
}
package { 'curl': 
	ensure => present,
}
exec { 'nodeprepare':
	command => 'curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - > /tmp/nodeprepare.output.txt',
}
package { 'nodejs':
	ensure => present,
}

name              "percona"
maintainer        "Phil Cohen"
maintainer_email  "github@phlippers.net"
license           "Apache 2.0"
description       "Installs Percona MySQL client and server"
long_description  "Please refer to README.md"
version           "0.14.5"

recipe "percona",                "Includes the client recipe to configure a client"
recipe "percona::package_repo",  "Sets up the package repository and installs dependent packages"
recipe "percona::client",        "Installs client libraries"
recipe "percona::server",        "Installs the server daemon"
recipe "percona::backup",        "Installs the XtraBackup hot backup software"
recipe "percona::toolkit",       "Installs the Percona Toolkit software"
recipe "percona::cluster",       "Installs the Percona XtraDB Cluster server components"
recipe "percona::configure_server", "Used internally to manage the server configuration."
recipe "percona::replication",   "Used internally to grant permissions for replication."
recipe "percona::access_grants", "Used internally to grant permissions for recipes"

#depends "apt"
#depends "yum"
depends "openssl"
depends "mysql", "~> 3.0"
depends "oscommon"

%w[debian ubuntu centos amazon scientific fedora redhat].each do |os|
  supports os
end

depends "openssl"

attribute "mysql/server_root_password",
  :display_name => "MySQL Server Root Password",
  :description => "Randomly generated password for the mysqld root user",
  :default => "randomly generated"

attribute "mysql/bind_address",
  :display_name => "MySQL Bind Address",
  :description => "Address that mysqld should listen on",
  :default => "ipaddress"

attribute "mysql/datadir",
  :display_name => "MySQL Data Directory",
  :description => "Location of mysql databases",
  :default => "/var/lib/mysql"

attribute "mysql/ec2_path",
  :display_name => "MySQL EC2 Path",
  :description => "Location of mysql directory on EC2 instance EBS volumes",
  :default => "/mnt/mysql"

attribute "mysql/tunable",
  :display_name => "MySQL Tunables",
  :description => "Hash of MySQL tunable attributes",
  :type => "hash"

attribute "mysql/tunable/key_buffer",
  :display_name => "MySQL Tuntable Key Buffer",
  :default => "250M"

attribute "mysql/tunable/max_connections",
  :display_name => "MySQL Tunable Max Connections",
  :default => "800"

attribute "mysql/tunable/wait_timeout",
  :display_name => "MySQL Tunable Wait Timeout",
  :default => "180"

attribute "mysql/tunable/net_read_timeout",
  :display_name => "MySQL Tunable Net Read Timeout",
  :default => "30"

attribute "mysql/tunable/net_write_timeout",
  :display_name => "MySQL Tunable Net Write Timeout",
  :default => "30"

attribute "mysql/tunable/back_log",
  :display_name => "MySQL Tunable Back Log",
  :default => "128"

attribute "mysql/tunable/table_cache",
  :display_name => "MySQL Tunable Table Cache for MySQL < 5.1.3",
  :default => "128"

attribute "mysql/tunable/table_open_cache",
  :display_name => "MySQL Tunable Table Cache for MySQL >= 5.1.3",
  :default => "128"

attribute "mysql/tunable/max_heap_table_size",
  :display_name => "MySQL Tunable Max Heap Table Size",
  :default => "32M"

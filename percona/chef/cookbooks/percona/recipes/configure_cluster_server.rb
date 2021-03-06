percona = node["percona"]
server  = percona["server"]
conf    = percona["conf"]
mysqld  = (conf && conf["mysqld"]) || {}
firstnode = false
headnode = ""

# get ip addresses - Barclamp proposal needs to be coded and not hard coded
service_name = node[:percona][:config][:environment]
proposal_name = service_name.split('-')
bcproposal = "bc-percona-"+proposal_name[2]
getdbip_db = data_bag_item('crowbar', bcproposal)
dbcont1 = getdbip_db["deployment"]["percona"]["elements"]["percona"][0]
dbcont2 = getdbip_db["deployment"]["percona"]["elements"]["percona"][1]
dbcont3 = getdbip_db["deployment"]["percona"]["elements"]["percona"][2]
cont_db = data_bag_item('crowbar', 'admin_network')
cont1_admin_ip = cont_db["allocated_by_name"]["#{dbcont1}"]["address"]
cont2_admin_ip = cont_db["allocated_by_name"]["#{dbcont2}"]["address"]
cont3_admin_ip = cont_db["allocated_by_name"]["#{dbcont3}"]["address"]
gcommaddr = "gcomm://" +  cont1_admin_ip + "," + cont2_admin_ip + "," + cont3_admin_ip
root_password = node["percona"]["server_root_password"]
debian_password = node["percona"]["server_debian_password"]

## check if an server config file is in place and if so, remove it (might replace this with a ruby block to rename
#ruby_block "removemyconf" do
  #block do
    #require 'date'
    ##if File.ctime(percona["main_config_file"]).to_date < Date.today
    #if File.exist?("/etc/mysql/my.cnf") && Date.parse(File.ctime("/etc/mysql/my.cnf").to_s) < Date.today
                #Chef::Log.info("****COE-LOG: Deleting pre-existing my.cnf config file")
                #File.delete(percona["main_config_file"])
        #end
  #end
  #action :create
#end

#template "/root/.my.cnf" do
#  variables(:root_password => root_password)
#  owner "root"
#  group "root"
#  mode 0600
#  source "my.cnf.root.erb"
#end

if server["bind_to"]
  ipaddr = Percona::ConfigHelper.bind_to(node, server["bind_to"])
  if ipaddr && server["bind_address"] != ipaddr
    node.override["percona"]["server"]["bind_address"] = ipaddr
    node.save
  end

  log "Can't find ip address for #{server["bind_to"]}" do
    level :warn
    only_if { ipaddr.nil? }
  end
else
  admin_vip = node[:haproxy][:admin_ip]
  node["percona"]["server"]["bind_address"] = admin_vip
  node.save

  log "Can't find ip address for #{server["bind_to"]}" do
    level :warn
    only_if { ipaddr.nil? }
  end
end

datadir = mysqld["datadir"] || server["datadir"]
user    = mysqld["username"] || server["username"]

# define the service
service "mysql" do
  supports :restart => true
  
  #If this is the first node we'll change the start and resatart commands to take advantage of the bootstrap-pxc command
  #Get the cluster address and extract the first node IP

  #cluster_address = node["percona"]["cluster"]["wsrep_cluster_address"].dup
  #cluster_address.slice! "gcomm://"
  #cluster_nodes = cluster_address.split(',')
  headnode = cont1_admin_ip 
  localipaddress= Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address 
  if cont1_admin_ip == localipaddress
	firstnode = true
	start_command "/usr/bin/service mysql bootstrap-pxc" #if platform?("ubuntu")
	restart_command "/usr/bin/service mysql stop && /usr/bin/service mysql bootstrap-pxc" #if platform?("ubuntu")
  end
  
  
  
  action server["enable"] ? :enable : :disable
end

# this is where we dump sql templates for replication, etc.
directory "/etc/mysql" do
  owner "root"
  group "root"
  mode 0755
end

# setup the data directory
directory datadir do
  owner user
  group user
  recursive true
  action :create
end

sleep 15

# install db to the data directory
execute "setup mysql datadir" do
  command "mysql_install_db --user=#{user} --datadir=#{datadir}"
  not_if "test -f #{datadir}/mysql/user.frm"
end

# check if an server config file is in place and if so, remove it (might replace this with a ruby block to rename
#file percona["main_config_file"] do
#  action :delete
#  ignore_failure true
#end

#file percona["main_config_file"] do # KR - I dont like this. 
#  action :delete 
#  ignore_failure true
#end

# setup the main server config file
template percona["main_config_file"] do
  source "my.cnf.#{conf ? "custom" : server["role"]}.erb"
  owner "root"
  group "root"
  mode "0744"
  variables( {
    "gcommaddr" => gcommaddr
  } )


  # If this is not the first node wait until the first node becomes available before restarting the service
  if firstnode
	notifies :restart, "service[mysql]", :immediately if node["percona"]["auto_restart"]
  else
	Chef::Log.info("****COE-LOG: Checking for MySQL service on #{headnode}, port 4567")
	i=0
	while !PortCheck.is_port_open headnode, "4567" 
		Chef::Log.info("****COE-LOG: waiting for first cluster node to become available - sleep 60 seconds - #{i} of 6")
		i+=1
		break if i==6 # break out after waiting 6 intervals
		sleep 60 # sleep for 60 seconds before retry
    end
  end
end


# now let's set the root password only if this is the initial install
execute "Update MySQL root password" do
  command "mysqladmin --user=root --password='' password '"+root_password+"'"
  only_if { node["platform_family"] != "debian" }  #on debian this should have already been taken care of with debconf-set-selections
  not_if "test -f /tmp/percona_grants.sql" #|| platform_family?("debian")
  #not_if node["platform_family"] == "debian"
  #not_if platform_family?("debian")
end


# setup the debian system user config
template "/etc/mysql/debian.cnf" do
  source "debian.cnf.erb"
  variables(:debian_password => debian_password)
  owner "root"
  group "root"
  mode 0640
  notifies :restart, "service[mysql]", :immediately if node["percona"]["auto_restart"]

  only_if { node["platform_family"] == "debian" }
end


if platform_family?('debian')
  ruby_block "add_mysqlchk_service" do
    block do
      file = Chef::Util::FileEdit.new("/etc/services")
      file.insert_line_if_no_match("mysqlchk", "mysqlchk        9200/tcp          #mysqlchk")
      file.write_file
    end
  end
  package "xinetd" do
    action :install
  end
end



#####################################
## CONFIGURE ACCESS FOR SST REPLICATION
#####################################
if firstnode
	sstAuth = node["percona"]["cluster"]["wsrep_sst_auth"].split(':')
	sstAuthName = sstAuth[0]
	sstauthPass = sstAuth[1]
	# Create the state transfer user
	unless File.exists?("/etc/mysql/userhold.txt") 
	   execute "add-mysql-user-sstuser" do
	   	command "/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"CREATE USER '#{sstAuthName}'@'localhost' IDENTIFIED BY '#{sstauthPass}'\""
	   	action :run
	   	#Chef::Log.info('****COE-LOG add-mysql-user-sstuser')
	   	#only_if { `/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"SELECT COUNT(*) FROM mysql.user where User='sstuser'"`.to_i == 0 }
	   end
	   # Grant priviledges
	   execute "grant-priviledges-to-sstuser" do
	   	#Chef::Log.info('****COE-LOG grant-priviledges-to-sstuser')
	   	command "/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO '#{sstAuthName}'@'localhost'\""
	   	action :run
	       #only_if { `/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"SELECT COUNT(*) FROM user where User='sstuser'"`.to_i == 0 }
	   end
         # Flush
	   execute "flush-mysql-priviledges" do
	   	#Chef::Log.info('****COE-LOG flush-mysql-priviledges')
	   	command "/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"FLUSH PRIVILEGES\""
	   	action :run
	       #only_if { `/usr/bin/mysql -u root -p"+root_password+" -D mysql -r -B -N -e \"SELECT COUNT(*) FROM user where User='sstuser'"`.to_i == 0 }
	   end
          template "/etc/mysql/userhold.txt" do
              source "userhold.txt.erb"
              owner "root"
              group "root"
              mode 0755
          end
      end
end

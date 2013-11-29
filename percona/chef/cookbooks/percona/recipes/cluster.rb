#include_recipe "percona::package_repo"
	
# install packages
case node["platform_family"]
when "debian"
directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  execute "preseed percona-server" do
    command "debconf-set-selections /var/cache/local/preseeding/percona-server.seed"
    action :nothing
  end

  template "/var/cache/local/preseeding/percona-server.seed" do
    source "percona-server.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed percona-server"), :immediately
  end


  package "percona-xtradb-cluster-server-5.5" do
    options "--force-yes"
  end
when "rhel"
  package "mysql-libs" do
    action :remove
  end

  package "Percona-XtraDB-Cluster-server"
end

include_recipe "percona::configure_cluster_server"

# access grants
include_recipe "percona::access_grants"

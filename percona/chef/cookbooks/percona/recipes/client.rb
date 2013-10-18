#include_recipe "percona::package_repo"
#include_recipe "mysql::client"

if platform_family?('debian')
#  chef_gem "chef-rewind"
#  require 'chef/rewind'

package "percona-xtradb-cluster-client-5.5" do
  action :install
  options "--force-yes"
end

end

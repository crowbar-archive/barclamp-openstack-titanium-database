# Cookbook Name:: percona
# Recipe:: monitoring
#
# Copyright 2012, CX Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

percona_plugins_tarball = "percona-monitoring-plugins-1.0.5.tar.gz"
#percona_plugins_url = "#{node['percona']['plugins_url']}/#{percona_plugins_tarball}"

include_recipe "nagios::common" if node["roles"].include?("nagios-client")

template "/etc/nagios/nrpe.d/percona_nrpe.cfg" do
  source "percona_nrpe.cfg.erb"
  mode "0644"
  group node[:nagios][:group]
  owner node[:nagios][:user]
  variables({
  })    
   notifies :restart, "service[nagios-nrpe-server]"
end if node["roles"].include?("nagios-client") 

directory "percona_plugins_dir" do
  path node['percona']['plugins_path']
  owner "root"
  group "root"
  mode 0755
end

cookbook_file "/var/cache/chef/cookbooks/percona/percona-monitoring-plugins-1.0.5.tar.gz" do
  source "percona-monitoring-plugins-1.0.5.tar.gz"
  owner "root"
  group "root"
  mode "0755"
  # action :create
end

execute "percona-extract-plugins" do
  command "tar zxf /var/cache/chef/cookbooks/percona/percona-monitoring-plugins-1.0.5.tar.gz --strip-components 2 -C #{node['percona']['plugins_path']}"
  creates "#{node['percona']['plugins_path']}/COPYING"
  # only_if do File.exist?("#{Chef::Config[:file_cache_path]}/#{percona_plugins_tarball}") end
  only_if do File.exist?("/var/cache/chef/cookbooks/percona/percona-monitoring-plugins-1.0.5.tar.gz") end
  action :run
end


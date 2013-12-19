

# Only prepare node on the first run.
installed = true
percona = search(:node, "roles:percona").first
if percona == nil
  installed = false
end

# check if an server config file is in place and if so, remove it (might replace this with a ruby block to rename
ruby_block "removemyconf" do
  block do
    require 'date'
    Chef::Log.info("****COE-LOG: Percona has already been installed: #{installed}")
    if installed == false
      #if File.ctime(percona["main_config_file"]).to_date < Date.today
      #if File.exist?("/etc/mysql/my.cnf") && Date.parse(File.ctime("/etc/mysql/my.cnf").to_s) < Date.today
      if File.exist?(node["percona"]["main_config_file"])
        Chef::Log.info("****COE-LOG: Deleting pre-existing my.cnf config file")
        File.delete(node["percona"]["main_config_file"])
      end
    end
  end
  action :create
end

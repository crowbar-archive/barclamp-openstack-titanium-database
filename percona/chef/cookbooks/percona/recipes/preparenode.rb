
# check if an server config file is in place and if so, remove it (might replace this with a ruby block to rename
ruby_block "removemyconf" do
  block do
    require 'date'
    #if File.ctime(percona["main_config_file"]).to_date < Date.today
    if File.exist?("/etc/mysql/my.cnf") && Date.parse(File.ctime("/etc/mysql/my.cnf").to_s) < Date.today
                Chef::Log.info("****COE-LOG: Deleting pre-existing my.cnf config file")
                File.delete(percona["main_config_file"])
        end
  end
  action :create
end

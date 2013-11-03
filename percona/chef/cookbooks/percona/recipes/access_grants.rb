#passwords = EncryptedPasswords.new(node, node["percona"]["encrypted_data_bag"])

# define access grants
template "/tmp/percona_grants.sql" do
  source "percona_grants.sql.erb"
  variables(
    :root_password        => node["percona"]["server_root_password"],
    :debian_user          => node["percona"]["server"]["debian_username"],
    :debian_password      => node["percona"]["server_debian_password"],
    :backup_password      => ""
  )
  owner "root"
  group "root"
  mode "0600"
end

# execute access grants
# root@localhost is already set - make sure all other root accounts have the same password - JPA
mysql_root_password = node["percona"]["server_root_password"]
execute "mysql-install-privileges" do
  command "/usr/bin/mysql --user=root --password=#{mysql_root_password} < /tmp/percona_grants.sql"
  action :nothing
  subscribes :run, resources("template[/tmp/percona_grants.sql]"), :immediately
end

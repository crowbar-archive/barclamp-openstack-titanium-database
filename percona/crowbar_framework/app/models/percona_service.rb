# Copyright 2011, Dell 
# Copyright 2012, Dell
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 

class PerconaService < ServiceObject

  def initialize(thelogger)
    @bc_name = "percona"
    @logger = thelogger
  end

  def create_proposal
    # TODO: ensure that only one proposal can be applied to a node
    @logger.debug("percona create_proposal: entering")
    base = super
    @logger.debug("percona create_proposal: leaving base part")

    nodes = NodeObject.all
    nodes.delete_if { |n| not n.admin? }
    unless nodes.empty?
      base["deployment"]["percona"]["elements"] = {
        "percona" => [ nodes.first.name ]
      }
    end

    @logger.debug("percona create_proposal: exiting")
    base
  end

  def apply_role_pre_chef_call(old_role, role, all_nodes)
    @logger.debug("Steve")
    @logger.debug("Database apply_role_pre_chef_call: entering #{all_nodes.inspect}")
    return if all_nodes.empty?

    # Make sure the bind hosts are in the admin network
    all_nodes.each do |n|
      node = NodeObject.find_node_by_name n

      admin_address = node.get_network_by_type("admin")["address"]
      node.crowbar[:percona] = {} if node.crowbar[:percona].nil?
      node.crowbar[:percona][:api_bind_host] = admin_address
      @logger.debug("Database api bind host: #{node.crowbar[:percona][:api_bind_host]}")
      node.save
    end
    
    
    sql_engine = role.default_attributes["percona"]["sql_engine"]
    @logger.debug(sql_engine)
    role.default_attributes["percona"][sql_engine] = {} if role.default_attributes["percona"][sql_engine].nil?
    role.default_attributes["percona"]["percona"]["db_maker_password"] = (old_role && old_role.default_attributes["percona"]["db_maker_password"]) || random_password

    role.default_attributes["percona"]["percona"]["server_debian_password"] = (old_role && old_role.default_attributes["percona"]["server_debian_password"]) || random_password
    role.default_attributes["percona"]["percona"]["server_root_password"] = (old_role && old_role.default_attributes["percona"]["server_root_password"]) || random_password
    role.default_attributes["percona"]["percona"]["server_repl_password"] = (old_role && old_role.default_attributes["percona"]["server_repl_password"]) || random_password
    @logger.debug("setting mysql specific attributes")
    

    # Copy the attributes for database/<sql_engine> to <sql_engine> in the
    # role attributes to avoid renaming all attributes everywhere in the
    # postgres and mysql cookbooks
    # (FIXME: is there a better way to achieve this?)
    role.default_attributes[sql_engine] = role.default_attributes["percona"][sql_engine]
    role.save

    @logger.debug("Database apply_role_pre_chef_call: leaving")
  end

end


# Configure the filesystem
include_recipe "cassandra-opsworks::ephemeral_xfs"

if node[:cassandra][:package][:use_package] == true
  include_recipe "cassandra-opsworks::deb"
else
  include_recipe "cassandra-opsworks::datastax"
end

version=node[:cassandra][:package][:version].match(/_(.*)_/m)[1].strip[0...3]

case version
when "1.1"
 config = "cassandra11.yaml"
 snitch = node[:cassandra11][:snitch]
 authority = node[:cassandra11][:authority]
when "1.2", "2.0", "2.1"
 config = "cassandra.yaml"
 snitch = node[:cassandra][:snitch]
 authority = node[:cassandra][:authorizer] 
else
 puts "Invalid version"
end

template File.join(node["cassandra"]["conf_dir"], 'cassandra.yaml') do
    source "#{config}.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    variables({
             :snitch => "#{snitch}",
             :authority => "#{authority}"
            })
    mode  0644
end

template File.join(node["cassandra"]["conf_dir"], 'cassandra-env.sh') do
    source "cassandra-env.sh.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    mode  0644
    notifies :restart, resources(:service => "cassandra")
end

if version = "1.2"
bash "comment_parameters_1_2" do
   user "root"
   code <<-EOF
      sed -i 's/^cas_contention_timeout_in_ms/#cas_contention_timeout_in_ms/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
      sed -i 's/^preheat_kernel_page_cache/#preheat_kernel_page_cache/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
   EOF
 end
end

if version = "2.1"
bash "comment_parameters_2_1" do
   user "root"
   code <<-EOF
      sed -i 's/^multithreaded_compaction/#multithreaded_compaction/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
      sed -i 's/^memtable_flush_queue_size/#memtable_flush_queue_size/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
      sed -i 's/^compaction_preheat_key_cache/#compaction_preheat_key_cache/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
      sed -i 's/^in_memory_compaction_limit_in_mb/#in_memory_compaction_limit_in_mb/' #{node["cassandra"]["conf_dir"]}/cassandra.yaml
      sed -i 's/jamm.0.2.5.jar/jamm.0.3.0.jar/' #{node["cassandra"]["conf_dir"]}/cassandra-env.sh
   EOF
 end
end

execute "cassandra_restart" do
   command "service cassandra restart"
end

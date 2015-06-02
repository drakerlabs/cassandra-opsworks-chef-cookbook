# Configure the filesystem
include_recipe "cassandra-opsworks::ephemeral_xfs"

if node[:cassandra][:package][:use_package] == true
  include_recipe "cassandra-opsworks::deb"
else
  include_recipe "cassandra-opsworks::datastax"
end

version=node[:package][:version].match(/_(.*)_/m)[1].strip[0...3]

case version
when "1.1"
 config = "cassandra11.yaml"
when "1.2", "2.0", "2.1"
 config = "cassandra.yaml"
end

template File.join(node["cassandra"]["conf_dir"], cassandra.yaml) do
    source "#{config}.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    mode  0644
end

template File.join(node["cassandra"]["conf_dir"], cassandra-env.sh) do
    source "cassandra-env.sh.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    mode  0644
    notifies :restart, resources(:service => "cassandra")
end


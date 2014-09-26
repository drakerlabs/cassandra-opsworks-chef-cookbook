# Configure the filesystem
include_recipe "cassandra-opsworks::ephemeral_xfs"

if node[:cassandra][:package][:use_package] == true
  include_recipe "cassandra-opsworks::deb"
else
  include_recipe "cassandra-opsworks::datastax"
end

%w(cassandra.yaml cassandra-env.sh).each do |f|
  template File.join(node["cassandra"]["conf_dir"], f) do
    source "#{f}.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    mode  0644
    notifies :restart, resources(:service => "cassandra")
  end
end

default[:cassandra] = {
  :cluster_name => "Test Cluster",
  :initial_token => "",
  :dsc_version => "dsc20",
  :version => '2.0.8',
  # package is used with deb.rb recipe
  :package => {
    :base_url => 'http://debian.datastax.com/community/pool/',
    :version => 'cassandra_2.0.8_all.deb',
    :sha => 'c50eb2dd434df30b1ef906c328cccd3dd6d0ba4e',
    :python_cql => 'python-cql_1.4.0-1_all.deb',
    :python_thrift => 'python-thrift-basic_0.8.0-1~ds+1_all.deb',
    :use_package => true
  },
  :user => "cassandra",
  :jvm  => {
    :xms => 32,
    :xmx => 512,
    :xss => "228k"
  },
  :limits => {
    :memlock => 'unlimited',
    :nofile  => 48000
  },
  :installation_dir => "/usr/local/cassandra",
  :bin_dir          => "/usr/local/cassandra/bin",
  :lib_dir          => "/usr/local/cassandra/lib",
  :conf_dir         => "/etc/cassandra/",
  # commit log, data directory, saved caches and so on are all stored under the data root. MK.
  :data_root_dir    => "/var/lib/cassandra/",
  :commitlog_dir    => "/var/lib/cassandra/",
  :log_dir          => "/var/log/cassandra/",
  :listen_address   => node[:ipaddress],
  :rpc_address      => node[:ipaddress],
  :max_heap_size    => nil,
  :heap_new_size    => nil,
  :vnodes           => 64,
  :seeds            => [],
  :concurrent_reads => 32,
  :concurrent_writes => 32,
  :snitch           => 'Ec2Snitch',
  :authenticator    => 'org.apache.cassandra.auth.PasswordAuthenticator',
  :authorizer       => 'org.apache.cassandra.auth.CassandraAuthorizer',
  :partitioner      => 'org.apache.cassandra.dht.Murmur3Partitioner',
  :native_transport => {
    :start       => true,
    :port        => 9042,
    :max_threads => 128
  }
}

# Set the OpsWorks specifics here

puts "Configured Snitch is #{node["cassandra"]["snitch"]}"

seed_array = []

# Add this node as the first seed
# If using the multi-region snitch, we must use the public IP address
if node["cassandra"]["snitch"] == "Ec2MultiRegionSnitch"
  seed_array << node["opsworks"]["instance"]["ip"]
else
  seed_array << node["opsworks"]["instance"]["private_ip"]
end

# Assumes opsworks layer is named cassandra
node["opsworks"]["layers"]["cassandra"]["instances"].each do |instance_name, values|
  # If using the multi-region snitch, we must use the public IP address
  if node["cassandra"]["snitch"] == "Ec2MultiRegionSnitch"
    seed_array << values["ip"]
  else
    seed_array << values["private_ip"]
  end
end
  
set[:cassandra][:seeds] = seed_array
default[:cassandra11] = {
       :snitch => 'org.apache.cassandra.locator.Ec2Snitch',
       :authority => 'org.apache.cassandra.auth.AllowAllAuthority'
}

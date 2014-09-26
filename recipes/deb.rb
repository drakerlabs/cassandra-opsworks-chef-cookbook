#
# Cookbook Name:: cassandra-opsworks
# Recipe:: datastax
#
# Copyright 2014, Ed Brady, Draker
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



# Provide some monitoring capabilities when logged in
package "htop" do
  action :install
end

package "libcommons-daemon-java" do
  action :install
end

package "libjna-java" do
  action :install
end

package "jsvc" do
  action :install
end

package "python-support" do
  action :install
end

package "openjdk-7-jre" do
  action :install
  # Don't install if Oracle Java (preferred) is already installed
  not_if "sudo update-alternatives --get-selections|grep -q '/usr/lib/jvm/java-7-oracle/jre/bin/java'"
end

# Force Java 7 as the default
execute "update-java-alternatives" do
  command "update-java-alternatives --set java-1.7.0-openjdk-amd64"
  # Don't install if Oracle Java (preferred) is already installed
  not_if "sudo update-alternatives --get-selections|grep -q '/usr/lib/jvm/java-7-oracle/jre/bin/java'"
end

# Download Python-Thrift
remote_file "/tmp/#{node[:cassandra][:package][:python_thrift]}" do
  source "#{node[:cassandra][:package][:base_url]}#{node[:cassandra][:package][:python_thrift]}"
end

# Install Python-Thrift
dpkg_package "python-thrift" do
  source "/tmp/#{node[:cassandra][:package][:python_thrift]}"
  action :install
end

# Download Python-CQL
remote_file "/tmp/#{node[:cassandra][:package][:python_cql]}" do
  source "#{node[:cassandra][:package][:base_url]}#{node[:cassandra][:package][:python_cql]}"
end

# Install Python-CQL
dpkg_package "python-cql" do
  source "/tmp/#{node[:cassandra][:package][:python_cql]}"
  action :install
end

# Download Cassandra
remote_file "/tmp/#{node[:cassandra][:package][:version]}" do
  source "#{node[:cassandra][:package][:base_url]}#{node[:cassandra][:package][:version]}"
  checksum node[:cassandra][:package][:sha]
end


# Install Cassandra
dpkg_package "cassandra_deb" do
  source "/tmp/#{node[:cassandra][:package][:version]}"
  action :install
end

service "cassandra" do
  supports :restart => true, :status => true
  action [:enable, :start]
end

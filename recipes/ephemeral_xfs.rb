#
# Cookbook Name:: cassandra-opsworks
# Recipe:: ephemeral_xfs
#
# Copyright 2013, Skye Book
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

# AWS preconfigures instance storage as ext3
# but we want to use XFS for storage.
# TODO: Eventually this should be updated to support
#       multiple instance stores in RAID-0

# Install XFS
package "xfsprogs" do
  action :install
end

# m1.xlarge and i2.2xlarge RAID-0
if node["opsworks"]["instance"]["instance_type"] == "m1.xlarge" || node["opsworks"]["instance"]["instance_type"] == "i2.2xlarge"
  target        = "/dev/md0"
  mountLocation = "/data"
  # Install Mdadm
  package "mdadm" do
    action :install
  end
  
  # Create data directory to mount RAID to
  directory mountLocation do
    owner node['cassandra']['user']
    group node['cassandra']['user']
    mode 00755
    action :create
    not_if { FileTest.blockdev?(target) }
  end

  # m1.xlarge instances have four 420GB HDDs
  if node["opsworks"]["instance"]["instance_type"] == "m1.xlarge"
    raidDevNumber = 4
    devList = [ "/dev/xvdb", "/dev/xvdc", "/dev/xvdd", "/dev/xvde" ]
    
  # I2.2xlarge instances have two 800GB SSDs
  elsif node["opsworks"]["instance"]["instance_type"] == "i2.2xlarge"
    raidDevNumber = 2
    devList = [ "/dev/xvdb", "/dev/xvdc" ]
  end
  
  execute "create raid" do
    command "sudo umount -d /dev/xvdb; yes |sudo mdadm --create #{target} --level=0 -c256 --raid-devices=#{raidDevNumber} #{devList.join(" ")}; mkfs.xfs -f #{target}"
    not_if { FileTest.blockdev?(target) }
  end

else
  target        = "/dev/xvdb"
  mountLocation = "/mnt"

  # Unmount the ephemeral storage provided by Amazon
  execute "umount" do
    command "sudo umount #{target}; mkfs.xfs -f #{target}"
  end
end


# Mount the new filesystem
mount mountLocation do
  device target
  fstype "xfs"
  options "rw"
  action :mount
end


# Make the mount accessible
execute "chmod" do
  command "chmod 777 #{mountLocation}"
end

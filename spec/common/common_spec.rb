require 'spec_helper'

# os name
describe file('/etc/redhat-release'), :if => os[:family] == 'redhat' do
  its(:content) { should match "Red Hat Enterprise Linux Server release 7.3 (Maipo)\n" }
end

# check partition
partition = [
             { m_point: '/boot/efi', m_device: '/dev/sda1', m_type: 'vfat', m_size: 262144, m_size_match: true },
             { m_point: '/boot', m_device: '/dev/sda2', m_type: 'xfs', m_size: 524288, m_size_match: true },
             { m_point: '/dump', m_device: '/dev/sda3', m_type: 'xfs', m_size: (host_inventory['memory']['total'].to_i * 1.1).to_i, m_size_match: false },
             { m_point: '/', m_device: '/dev/sda5', m_type: 'xfs', m_size: 40 * 1024, m_size_match: false },
            ]

partition.each do |part|
  describe file(part[:m_point]) do
    it do
      should be_mounted.with(
                             :device  => part[:m_device],
                             :type    => part[:m_type],
                            )
    end
  end

  describe command("fdisk -s #{part[:m_device]}") do
    if part[:m_size_match]
      its('stdout.to_i') { should eq part[:m_size] }
    else
      its('stdout.to_i') { should >= part[:m_size] }
    end
  end
end

describe file('/proc/swaps') do
  its(:content) { should match /^\/dev\/sda4 *partition *.*$/ }
end

describe command("fdisk -s /dev/sda4") do
  its('stdout.to_i') { should >= host_inventory['memory']['total'].to_i * 2 }
end

# check runlevel
describe command('systemctl get-default'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match "multi-user.target" }
end

# check rpmlist
rpmlist = File.read('spec/common/files/rpmlist.txt')
describe command('rpm -qa | sort'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match rpmlist }
end

# check tuned
describe file('/etc/tuned/default/tuned.conf'), :if => os[:family] == 'redhat' do
  its(:content) { should match /^include *= *virtual-guest$/ }
end

describe command('sysctl -a'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match /^net.ipv4.ip_local_port_range = 32770\t*64999$/ }
  its(:stdout) { should match /^net.core.somaxconn = 511$/ }
  its(:stdout) { should match /^net.ipv4.tcp_keepalive_intvl = 5$/ }
  its(:stdout) { should match /^net.ipv4.tcp_keepalive_probes = 5$/ }
  its(:stdout) { should match /^net.ipv4.tcp_keepalive_time = 60$/ }
end

# disable selinux
describe selinux, :if => os[:family] == 'redhat' do
  it { should be_disabled }
end

# disable dns
describe file('/etc/nsswitch.conf'), :if => os[:family] == 'redhat' do
  its(:content) { should match /^hosts:      files myhostname$/ }
end

# disable firewalld
describe service('firewalld'), :if => os[:family] == 'redhat' do
  it { should_not be_enabled }
  it { should_not be_running }
end

# disable virbr0
describe interface('virbr0'), :if => os[:family] == 'redhat' do
  it { should_not exist }
end

# enabel bond0
describe bond('bond0'), :if => os[:family] == 'redhat' do
  it { should exist }
  it { should have_interface 'enp0s3' }
  it { should have_interface 'enp0s8' }
end

# enable chronyd
describe service('chronyd'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
end

describe command('chronyc sources'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match /^\^\*/ }
end

# enable kdump
describe service('kdump'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
end

# check user
describe user('hidepin'), :if => os[:family] == 'redhat' do
  it { should belong_to_group 'hidepin' }
end

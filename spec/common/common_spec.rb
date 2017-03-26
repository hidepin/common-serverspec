require 'spec_helper'

# os name
describe file('/etc/redhat-release'), :if => os[:family] == 'redhat' do
  its(:content) { should match "Red Hat Enterprise Linux Server release 7.3 (Maipo)\n" }
end

# check partition device
partition = [
             { m_point: '/boot/efi', m_device: '/dev/sda1', m_type: 'vfat' },
             { m_point: '/boot', m_device: '/dev/sda2', m_type: 'xfs' },
             { m_point: '/dump', m_device: '/dev/sda3', m_type: 'xfs' },
             { m_point: '/', m_device: '/dev/sda5', m_type: 'xfs' },
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
end

describe file('/proc/swaps') do
  its(:content) { should match /^\/dev\/sda4 *partition *.*$/ }
end

# disable selinux
describe selinux, :if => os[:family] == 'redhat' do
  it { should be_disabled }
end

# check rpmlist
rpmlist = File.read('spec/common/files/rpmlist.txt')
describe command('rpm -qa | sort'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match rpmlist }
end


# disable dns
describe file('/etc/nsswitch.conf'), :if => os[:family] == 'redhat' do
  its(:content) { should match /^hosts:      files myhostname$/ }
end

# check runlevel
describe command('systemctl get-default'), :if => os[:family] == 'redhat' do
  its(:stdout) { should match "multi-user.target" }
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

# enabel enp0s3
describe interface('enp0s3'), :if => os[:family] == 'redhat' do
  it { should exist }
end

# enable chronyd
describe service('chronyd'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
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

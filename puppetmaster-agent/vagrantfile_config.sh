#!/bin/bash

vagrant plugin list | grep -q vagrant-hosts
if [ $? -eq "1" ]; then
   vagrant plugin install vagrant-hosts
fi
vagrant plugin list | grep -q vagrant-vbguest
if [ $? -eq "1" ]; then
   vagrant plugin install vagrant-vbguest
fi

cat << 'EOF' > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
domain = 'example.com'
box = 'centos/7'

puppet_nodes = [
  {:hostname => 'puppet',  :ip => '172.16.32.10', :box => box, :fwdhost => 8140, :fwdguest => 8140, :ram => '1280'},
  {:hostname => 'client1', :ip => '172.16.32.11', :box => box},
  {:hostname => 'client2', :ip => '172.16.32.12', :box => box},
]

$setupscript = <<END
  yum -y update
  yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
  yum -y install puppet-agent vim telnet nmap
  localectl set-keymap it
  timedatectl set-timezone Europe/Rome
  GTIME=$(cat /etc/default/grub | grep "GRUB_TIMEOUT=")
  sed -i "s/$GTIME/GRUB_TIMEOUT=0/" /etc/default/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg
  echo 'supercede domain-name "example.com";' > /etc/dhcp/dhclient.conf
  sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0
  systemctl disable firewalld
END

Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  puppet_nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = node[:box]
      node_config.vm.hostname = node[:hostname] + '.' + domain
      node_config.vm.network "private_network", ip: node[:ip]

      if node[:fwdhost]
        node_config.vm.network "forwarded_port", guest: node[:fwdguest], host: node[:fwdhost]
      end

      memory = node[:ram] ? node[:ram] : 256;
      node_config.vm.provider "virtualbox" do |vb|
        vb.customize [
          'modifyvm', :id,
          '--name', node[:hostname],
          '--memory', memory.to_s
        ]
      end

      node_config.vm.provision "shell", inline: $setupscript
      node_config.vm.provision :hosts, :sync_hosts => true
      if node[:hostname] == "puppet"
        node_config.vm.provision "shell",
        inline: "yum -y install puppetserver && systemctl enable puppetserver; sed -i 's/-Xms2g -Xmx2g/-Xms768m -Xmx768m/' /etc/sysconfig/puppetserver; systemctl start puppetserver; echo '*." + domain + "' > /etc/puppetlabs/puppet/autosign.conf"
      end
    end
  end
end
EOF

vagrant up

vagrant reload puppet
for i in $(vagrant status | grep "running " | awk '{print $1}' | grep -v puppet)
do
  vagrant reload $i
done

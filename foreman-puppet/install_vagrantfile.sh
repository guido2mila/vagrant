#!/bin/sh

vagrant plugin list | grep -q vagrant-hostmanager
if [ $? -eq "1" ]; then
  vagrant plugin install vagrant-hostmanager
fi
vagrant plugin list | grep -q vagrant-vbguest
if [ $? -eq "1" ]; then
  vagrant plugin install vagrant-vbguest
fi

cat << 'EOF' > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes_config = (JSON.parse(File.read("nodes.json")))['nodes']

Vagrant.configure("2") do |config|
  nodes_config.each do |node|
    node_name   = node[0] # name of node
    node_values = node[1] # content of node

    config.vbguest.auto_update = true
    config.vbguest.iso_path = "http://download.virtualbox.org/virtualbox/%{version}/VBoxGuestAdditions_%{version}.iso"
    
    config.vm.box = node_values[':box']

    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    config.vm.define node_name do |config|
      # configures all forwarding ports in JSON array
      ports = node_values['ports']
      ports.each do |port|
        config.vm.network :forwarded_port,
          host:  port[':host'],
          guest: port[':guest'],
          id:    port[':id']
      end

      config.vm.hostname = node_name
      config.vm.network :private_network, ip: node_values[':ip']

      config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", node_values[':memory']]
        vb.customize ["modifyvm", :id, "--name", node_name]
      end

      config.vm.provision :shell, :path => node_values[':bootstrap']
    end
  end
end
EOF

#!/bin/sh

sudo cat /etc/dhcp/dhclient.conf|grep -q "supercede"
if [ $? == 0 ]; then
  echo "First node configuration already done"
else
  sudo yum -y update
  sudo yum -y install vim telnet nmap net-tools wget psmisc
  sudo localectl set-keymap it
  sudo timedatectl set-timezone Europe/Rome
  sudo sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/" /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  echo 'supercede domain-name "example.com";' | sudo tee /etc/dhcp/dhclient.conf
  sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
  sudo setenforce 0
  sudo systemctl disable firewalld
fi

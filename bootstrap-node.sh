#!/bin/sh

sudo cat /etc/dhcp/dhclient.con|grep -q "supercede"
if [ $? == 0 ]; then
  echo "First node configuration already done"
else
  sudo yum -y update
  sudo yum -y install vim telnet nmap
  sudo localectl set-keymap it
  sudo timedatectl set-timezone Europe/Rome
  GTIME=$(sudo cat /etc/default/grub | grep -q "GRUB_TIMEOUT=")
  sudo sed -i "s/$GTIME/GRUB_TIMEOUT=0/" /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  sudo echo 'supercede domain-name "example.com";' > /etc/dhcp/dhclient.conf
  sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
  sudo setenforce 0
  sudo systemctl disable firewalld
fi

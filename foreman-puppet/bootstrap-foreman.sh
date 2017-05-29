#!/bin/sh

rpm -qa|grep -q foreman
if [ $? == 0 ]; then
  echo "Foreman appears to already be installed"
else
  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
  sudo yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && \
  sudo yum -y install http://yum.theforeman.org/releases/1.15/el7/x86_64/foreman-release.rpm && \
  sudo yum -y install foreman-installer && \
  sudo foreman-installer

  # First run the Puppet agent on the Foreman host which will send the first Puppet report to Foreman,
  # automatically creating the host in Foreman's database
  sudo puppet agent --test

  # Optional, install some optional puppet modules on Foreman server to get started...
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-ntp
  sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-git
fi

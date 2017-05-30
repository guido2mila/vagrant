#!/bin/sh

rpm -qa|grep -q puppet-agent
if [ $? == 0 ]; then
  echo "Puppet agent appears to already be installed, agent version $(puppet agent --version)"
else
  sudo yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && \
  sudo yum -y install puppet-agent
  # Easier to set run interval to 120s for testing (reset to 30m for normal use)
  echo "    server = foreman.example.com" | sudo tee --append /etc/puppetlabs/puppet/puppet.conf 2> /dev/null && \
  echo "    runinterval = 120s" | sudo tee --append /etc/puppetlabs/puppet/puppet.conf 2> /dev/null
  sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
  sudo /opt/puppetlabs/bin/puppet agent --test
fi

#!/bin/sh

rpm -qa|grep -q foreman
if [ $? == 0 ]; then
  echo "Foreman appears to already be installed"
else
  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
  sudo yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && \
  sudo yum -y install http://yum.theforeman.org/releases/1.15/el7/x86_64/foreman-release.rpm && \
  sudo yum -y install foreman-installer
  echo "*.example.com"  | sudo tee --append /etc/puppetlabs/puppet/autosign.conf 2> /dev/null

  #run the foreman installer
  #login with admin/changeme (https://foreman.example.com)
  #sudo foreman-installer --foreman-admin-password=changeme

  #installing theforeman and openscap plugin
  sudo foreman-installer --foreman-admin-password=changeme --enable-foreman-plugin-openscap --enable-foreman-proxy-plugin-openscap
  sudo puppet module install theforeman-foreman_scap_client
  #creating default SCAP content
  sudo foreman-rake foreman_openscap:bulk_upload:default

  sudo sed -i 's/.*\ secure_path\ .*/Defaults    secure_path = \/sbin:\/bin:\/usr\/sbin:\/usr\/bin:\/opt\/puppetlabs\/bin/' /etc/sudoers

  # First run the Puppet agent on the Foreman host which will send the first Puppet report to Foreman,
  # automatically creating the host in Foreman's database
  sudo /opt/puppetlabs/bin/puppet agent --test

  # install some optional puppet modules on Foreman server
  # sudo /opt/puppetlabs/bin/puppet module install puppetlabs-ntp
  # sudo /opt/puppetlabs/bin/puppet module install puppetlabs-git
fi

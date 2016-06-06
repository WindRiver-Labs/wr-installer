FROM ubuntu:xenial
MAINTAINER hongxu.jia@windriver.com
USER root
WORKDIR /mnt
VOLUME /tmp
COPY host_ubuntu /tmp/
COPY installer-vb64.sh /usr/sbin/

# Speed up apt-get
RUN /bin/bash -c 'sed -i "s/archive/cn.archive/g" /etc/apt/sources.list'
RUN /bin/bash -c 'apt-get update'

# Install tools
RUN /bin/bash -c 'apt-get install -y lsb-release wget vim net-tools openssh-server openssh-client'

# If ssh server works, it also needs to set root password and /etc/init.d/ssh
# start in container
RUN /bin/bash -c 'sed -i "s/^PermitRootLogin.*$/PermitRootLogin yes/g" /etc/ssh/sshd_config'

# In docker, guest os in container reuse host os kernel, if they have different
# distribution code name, the guest os could not install linux-headers pacakge
# that matches to host os which caused virtualbox installation failed. So we
# add host os source list to guest.
RUN /bin/bash -c 'cp /etc/apt/sources.list /etc/apt/sources.list.d/'
RUN /bin/bash -c 'sed -i "s#xenial#$(cat /tmp/host_ubuntu)#g" /etc/apt/sources.list.d/sources.list'
RUN /bin/bash -c 'wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -'
RUN /bin/bash -c 'wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -'
RUN /bin/bash -c 'echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list'
RUN /bin/bash -c 'apt-get update'
RUN /bin/bash -c 'apt-get install -y "linux-headers-$(uname -r)"'
RUN /bin/bash -c 'apt-get install -y virtualbox-5.0 --fix-missing'
RUN /bin/bash -c 'wget http://download.virtualbox.org/virtualbox/5.0.20/Oracle_VM_VirtualBox_Extension_Pack-5.0.20-106931.vbox-extpack'
RUN /bin/bash -c 'VBoxManage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-5.0.20-106931.vbox-extpack'

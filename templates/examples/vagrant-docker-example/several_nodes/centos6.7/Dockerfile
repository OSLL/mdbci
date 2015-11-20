FROM centos:6.7
MAINTAINER OSLL <osll@osll.ru>

#ENV SHELL /bin/bash

RUN yum update -y && \
    yum --assumeyes install openssh-server openssh-clients sudo curl wget iptables which ruby1.9.1 ruby1.9.1-dev make && \
    yum clean all

RUN /etc/init.d/sshd start
RUN sed -i 's/.*requiretty$/Defaults !requiretty/' /etc/sudoers


# Create and configure vagrant user
RUN groupadd vagrant && \
    useradd -c "Vagrant" -g vagrant -d /home/vagrant -m -s /bin/bash vagrant && \
    echo 'vagrant:vagrant' | chpasswd && \
    mkdir -p /etc/sudoers.d && \
    echo 'vagrant	ALL=(ALL)	NOPASSWD:ALL' >> /etc/sudoers.d/vagrant && \
    chmod 0440 /etc/sudoers.d/vagrant


# Configure SSH access
RUN mkdir -pm 700 /home/vagrant/.ssh && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' > /home/vagrant/.ssh/authorized_keys && \
    chmod 0600 /home/vagrant/.ssh/authorized_keys && \
    chown -R vagrant:vagrant /home/vagrant/.ssh


# Install chef
RUN curl -L https://www.opscode.com/chef/install.sh | bash -s -- -P container


# Clean up when done.
#RUN yum clean all


# daemonize sshd
CMD ["/usr/sbin/sshd", "-D", "-e"]
EXPOSE 22

FROM opensuse:tumbleweed
MAINTAINER OSLL <osll@osll.ru>

#RUN zypper -n --gpg-auto-import-keys ar http://download.opensuse.org/factory/repo/oss/ OSS

RUN zypper -n ref && \
    zypper -n up --skip-interactive && \
    zypper --non-interactive --gpg-auto-import-keys install -y openSSH sudo wget iptables SuSEfirewall2 curl

ENV SHELL /bin/sh


RUN sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
#RUN sed -i 's/#ChallengeResponseAuthentication no/ChallengeREsponseAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

CMD ["/bin/bash", "-c", "rcsshd restart"]

RUN sed -i 's/.*requiretty$/Defaults !requiretty/' /etc/sudoers

# Create and configure vagrant user
RUN groupadd vagrant && \
    useradd -m -g vagrant -d /home/vagrant -s /bin/bash vagrant && \
    echo 'vagrant:vagrant' && \
    echo 'vagrant	ALL=(ALL)	ALL' >> /etc/sudoers.d/vagrant && \
    chmod 0440 /etc/sudoers.d/vagrant

# create ssh host keys for sshd
RUN ssh-keygen -A

# Configure SSH access
RUN mkdir -p /home/vagrant/.ssh && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' > /home/vagrant/.ssh/authorized_keys && \
    chmod 0600 /home/vagrant/.ssh/authorized_keys && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    chmod 0700 /home/vagrant/.ssh


# install Chef-Solo
#ADD install.sh /home/vagrant/
RUN wget --no-check-certificate https://www.opscode.com/chef/install.sh -P /home/vagrant
RUN chmod +x /home/vagrant/install.sh
#RUN /home/vagrant/install.sh 
#| /bin/sh -s -- -P container

# daemonize sshd
CMD ["/usr/sbin/sshd", "-D"]
EXPOSE 22

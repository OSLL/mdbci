FROM opensuse:tumbleweed
MAINTAINER OSLL <osll@osll.ru>

#RUN zypper -n --gpg-auto-import-keys ar http://download.opensuse.org/factory/repo/oss/ OSS

RUN zypper -n ref && \
    zypper -n up --skip-interactive && \
    zypper --non-interactive --gpg-auto-import-keys install -y openSSH sudo wget iptables SuSEfirewall2

ENV SHELL /bin/bash

# start openssh
#RUN /etc/init.d/sshd start
#CMD ["/bin/bash", "-c", "systemctl enable sshd"]
#CMD ["/bin/bash", "-c", "systemctl start sshd"]
#CMD ["/bin/bash", "-c", "chkconfig sshd on"]
#CMD ["/bin/bash", "-c", "insserv sshd"]
#CMD ["/bin/bash", "-c", "rcsshd start"]

RUN sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
#RUN sed -i 's/#ChallengeResponseAuthentication no/ChallengeREsponseAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
#RUN echo 'root:13579Rh' | chpasswd

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

# Install chef
RUN curl -L https://www.opscode.com/chef/install.sh | /bin/bash

# Clean up APT when done.
#zypper clean
#RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#CMD ["/bin/bash", "-c", "systemctl restart sshd"]

#EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EXPOSE 22

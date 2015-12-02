FROM ubuntu

# Preparin dependencies
RUN apt-get -y install wget
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:webupd8team/java -y
RUN apt-get update
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN apt-get -y install oracle-java7-installer
RUN apt-get -y install git

# Downloading latest jenkins
RUN wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war

# Opening port
EXPOSE 5555

# Start
ADD ./startup.sh /etc/
CMD bash -c "/etc/startup.sh"


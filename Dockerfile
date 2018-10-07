FROM jenkins/jenkins:2.144
MAINTAINER Zohar Nyego <zoharngo@gmail.com>

# Suppress apt installation warnings
ENV DEBIAN_FRONTED=noninteractive

# Used to set the docker group ID
# Set default value of 497, which is the group ID used by AWS Linux ECS Instance
ARG DOCKER_GID=998

# Used to control Docker Compose versions installed
ARG DOCKER_COMPOSE=1.22.0

# Change to root user
USER root


# Create 'docker' group with provided group ID 
# and add 'jenkins' user to it
RUN groupadd -g ${DOCKER_GID:-998} docker && \  
    usermod -a -G docker jenkins && \
    usermod -a -G users jenkins

# Install helpers
RUN apt-get update -y && \
    apt-get install nano tree

# Install base packages
RUN apt-get update -y && \
    apt-get install python-dev \
    python-setuptools \
    gcc make libssl-dev -y && \
    easy_install pip

# Install 'docker-ce' and it's dependencies 
# https://docs.docker.com/engine/installation/linux/docker-ce/debian/
RUN apt-get update -y && \  
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        docker-ce && \
    apt-get clean

# Install Docker Compose
RUN pip install docker-compose==${DOCKER_COMPOSE:-1.22.0} && \
    pip install ansible boto boto3

RUN chgrp jenkins /usr/share/jenkins
RUN chmod -R g+rwx /usr/share/jenkins

# Run Jenkins as dedicated non-root user
USER jenkins  

# Add jenkins plugins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh $(cat /usr/share/jenkins/plugins.txt)
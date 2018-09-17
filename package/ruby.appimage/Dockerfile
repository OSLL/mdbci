# Beware: only meant for use to build ruby appimages

FROM ubuntu:14.04

ARG UNAME=builduser
ARG UID=1000
ARG GID=1000

MAINTAINER "Andrey Vasilyev <andrey.vasilyev@fruct.org>"

ENV DEBIAN_FRONTEND=noninteractive \
    DOCKER_BUILD=1

# Install all dependencies required by the ruby build
# and wget required by the gen_appimage.sh
RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm3 \
    libgdbm-dev \
    liblzma-dev \
    patch \
    wget \
    apt-transport-https \
    libcairo2 \
    sudo \
    vim \
    software-properties-common

# Install and configure GCC 8 to build ruby and packages
# Inspiried by https://gist.github.com/application2000/73fd6f4bf1be6600a2cf9f56315a2d91
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install gcc-8 g++-8 -y && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8;

# Create /workspace directory to use for mounting build environment
RUN addgroup --gid $GID $UNAME
RUN adduser --uid $UID --gid $GID --shell /bin/bash --home /workspace $UNAME
COPY gen_appimage.sh /workspace
RUN install -m 0755 -o $UID -g $GID -d /workspace/application
# Allow to run sudo without password for this user
RUN echo "$UNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /workspace/application

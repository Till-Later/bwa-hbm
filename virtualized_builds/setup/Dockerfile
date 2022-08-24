FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get install -y \
      vim \
      curl \
      ca-certificates\
      build-essential \
      openssh-client \
      git \
      xterm \
      tmux \
      libncurses-dev \
      python3 \
      python3-pystache \
      python3-yaml \
      python3-pip \
      libncurses5-dev \
      htop \
      nano \
      python3.8 \
      python3.8-dev \
      python3.8-distutils \
      python3.8-venv \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
RUN python3.8 -m pip install reprint
ENV DEBIAN_FRONTEND=

# copy in config file
COPY install_config.txt /

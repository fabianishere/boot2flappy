# Pull base image.
FROM ubuntu:latest
MAINTAINER Fabian Mastenbroek <mail.fabianm@gmail.com>

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential locales && \
  apt-get install -y software-properties-common && \
  apt-get install -y gdb cmake && \
  apt-get install -y binutils-mingw-w64 gcc-mingw-w64-x86-64 && \
  apt-get install -y dosfstools mtools xorriso && \
  locale-gen "en_US.UTF-8" && update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set environment variables.
ENV HOME=/root
ENV APP_HOME=$HOME/boot2flappy
# Create source volue
VOLUME $APP_HOME

# Define working directory.
WORKDIR $APP_HOME

# Define default command.
CMD ["/bin/sh", "-c", "mkdir -p build && cd build && cmake .. && make img"]

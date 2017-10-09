# Pull base image.
FROM ubuntu:latest

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y gdb nasm byobu curl git htop man unzip vim wget cmake binutils-mingw-w64 gcc-mingw-w64-x86-64 xorriso mtools valgrind && \
  locale-gen "en_US.UTF-8" && update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["/bin/sh", "-c", "mkdir build && cd build && cmake .. && make img"]

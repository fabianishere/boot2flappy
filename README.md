boot2flappy
[![Build Status](https://travis-ci.org/fabianishere/boot2flappy.svg?branch=master)](https://travis-ci.org/fabianishere/boot2flappy)
===========
Flappy Bird for UEFI written in x86 Assembly.

![Screenshot](resources/screenshot.png)

## Getting the source
Download the source code by running the following code in your command prompt:
```sh
$ git clone https://github.com/fabianishere/boot2flappy.git --recursive
```
or simply [grab](https://github.com/fabianishere/boot2flappy/archive/master.zip) 
a copy of the source code as a Zip file.

## Building
We provide two ways for building the project: manually on your local system or
in a container using Docker. If installing the required dependencies is not
trivial or unwanted, we suggest building the project with [Docker](#docker).

Make sure you have also downloaded the `deps/gnu-efi` submodule, which may be
done via:
```shell
$ git submodule update --init
```

### Manual
Create the build directory.
```sh
$ mkdir build
$ cd build
```
boot2flappy requires CMake and a specific C cross-compiler (namely `mingw-w64-x86-64`) in order to build.
On Ubuntu, please install the following packages:

- binutils-mingw-w64 
- gcc-mingw-w64-x86-64

Then, simply create the Makefiles:
```sh
$ cmake ..
```
and finally, build it using the building system you chose (e.g. Make):
```sh
$ make
```

### Docker
Build the project with the provided `fabianishere/boot2flappy` container as
follows. Make sure you run the command in the project root directory.

```sh
$ docker run --rm -it -v `pwd`:/root/boot2flappy fabianishere/boot2flappy
```

This will build the project in the `build/` directory.

## Playing

### QEMU
After building the project, in the build directory, run the following code in 
your command prompt:
```sh
$ vm/start.sh
```
This will start a QEMU virtual machine in which you can play the game. Make
sure QEMU is installed.

## Why
One of the assignments for the Computer Organisation course of 2016 at Delft University of Technology
was to create a bootable game in x86 assembly. Why not create a simple EFI game
with nice graphics?

## License
The code is released under the MIT license. See the `LICENSE` file.

All sprite files in the `resources` directory: all copyrights belong to their 
respective owners. The files are used for education purpose only.

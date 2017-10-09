#!/bin/bash
ARCH=${ARCH:-x86_64}

qemu-system-$ARCH -bios $(dirname $0)/bios.bin -drive format=raw,file=fat:rw:$(dirname $0)/hda-contents


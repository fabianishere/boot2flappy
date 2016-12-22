#!/bin/bash
ARCH=${ARCH:-x86_64}

qemu-system-$ARCH -bios $(dirname $0)/bios.bin -hda fat:$(dirname $0)/hda-contents


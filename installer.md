# Target Installer

Three main use cases:

1) Minimal installer image which contains ext3 image from target build
to be copied to local disk. Requires 2 builds.

2) Minimal installer image which contains rpms from target build to be
installed to local disk. Requires 2 builds.

3) Any image which also contains installer and all the rpms used to
build that image. Requires single build.

Note: The build and installer board configuration should be the same.

## Use Case 1: Target installer with image

Create an the target build image that will be installed onto the
target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std \
    --enable-bootimage=ext3
    make all


Create the installer image and point to ext3 image:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-core \
    --enable-target-installer=yes \
    --with-installer-target-build=<dir1>/export/qemux86-64-glibc-std-standard-dist.ext3
    make all

## Use case 2: Target installer with rpms

For use case #2, create the target build that will be
installed onto the target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std \
    make all

Create the installer image and point to top level of build:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-core \
    --enable-target-installer=yes \
    --with-installer-target-build=<dir1>
    make all

## Use case 3: Reuse installer rpms to install on target

Create the installer image without specifying target build:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-core \
    --enable-target-installer=yes \
    make all

## Testing

Create the qemu disk:

    host-cross/usr/bin/qemu-img create -f qcow hd0.vdisk 5000M

Start qemu with installer image:

    make start-target \
    TOPTS="-cd export/qemux86-64-glibc-core-standard-dist.iso \
    -no-kernel -disk hd0.vdisk -gc"

## Grub 0.97

To use grub 0.97 instead of grub 1.99+, set the grub preferred
version:

    PREFERRED_VERSION_grub = "0.97"

Unfortunately there seems to be a bug which requires this be added to
local.conf. There are several other restrictions for grub 0.97:
- Only builds on 32bit bsp
- If installer image is 32bit and target image is 64bit, qemu in
  installer build cannot boot target.

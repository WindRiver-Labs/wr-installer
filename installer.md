# Target Installer

Three main use cases:

1) Installer image which contains ext2, ext3 or ext4 image from target
   build to be copied to local disk. Requires 2 builds.

2) Installer image which contains rpms from target build to be installed
   to local disk. Requires 2 builds.

3) Any image which also contains installer and all the rpms used to
   build that image. Requires single build.

Note: The build and installer board configuration should be the same.

## Use Case 1: Target installer with image

Create the target build image that will be installed onto the target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std+installer-support \
    --enable-bootimage=ext3
    make all


Create the installer image and point to ext3 image:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=wr-installer \
    --enable-target-installer=yes \
    --with-installer-target-build=<dir1>/export/qemux86-64-glibc-std-standard-dist.ext3
    make all

## Use case 2: Target installer with rpms

For use case #2, create the target build that will be
installed onto the target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std+installer-support \
    make all

Create the installer image and point to top level of build:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=wr-installer \
    --enable-target-installer=yes \
    --with-installer-target-build=<dir1>
    make all

## Use case 3: Reuse installer rpms to install on target

Create the installer image without specifying target build:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=qemux86-64 \
    --enable-kernel=standard --enable-rootfs=wr-installer \
    --enable-target-installer=yes \
    make all

## Testing

Create the qemu disk:

    host-cross/usr/bin/qemu-img create -f qcow hd0.vdisk 5000M

Start qemu with installer image:

    make start-target \
    TOPTS="-m 1024 -cd export/qemux86-64-glibc-core-standard-dist.iso \
    -no-kernel -disk hd0.vdisk -gc"

Add EX_TARGET_QEMU_OPTS="-vnc :4" to start a VNC capable session...

## Grub 0.97

To use grub 0.97 instead of grub 1.99+, set the grub preferred
version:

    PREFERRED_VERSION_grub = "0.97"

Unfortunately there seems to be a bug which requires this be added to
local.conf. There are several other restrictions for grub 0.97:
- Only builds on 32bit bsp
- If installer image is 32bit and target image is 64bit, qemu in
  installer build cannot boot target.

## Adding custom installer.conf to installer image

The intaller script can read answers from /etc/installer.conf to help
speed up the installation process.  To add one to the installer image
requires the user to either copy the file to their project directory and/or
configure their local.conf file.

    cp <path>/installer.conf <installer_build_dir>/bitbake_build/conf/.

    or

    edit <installer_build_dir>/bitbake_build/conf/local.conf
    WRL_INSTALLER_CONF = "/my/installer.conf"

## The kickstart installation
The installer can support the kickstart installs, you can use the ks
file from /root/anaconda-ks.cfg after the installation and edit it for
later installs, you can specific the ks file by either of the following
3 ways:
- Set KICKSTART_FILE in the conf file (e.g.: local.conf)
- Put it to <installer-target-build>/anaconda-ks.cfg
- Put it to <installer-build>/anaconda-ks.cfg

Then the build will take it and start the kickstart installs by default
when you start the target.

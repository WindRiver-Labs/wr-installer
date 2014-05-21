# Target Installer

Two main use cases, each of them requires two builds, one is for the
target build, the other one is for the installer itself.

1) Installer image which contains ext2, ext3 or ext4 image from target
   build to be copied to local disk.

2) Installer image which contains rpms from target build to be installed
   to local disk.

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

## Testing

Create the qemu disk:

    host-cross/usr/bin/qemu-img create -f qcow hd0.vdisk 5000M

Start qemu with installer image:

    make start-target \
    TOPTS="-m 2048 -cd export/qemux86-64-installer-standard-dist.iso \
    -no-kernel -disk hd0.vdisk -gc" EX_TARGET_QEMU_OPTS="-vga vmware"

Add "-vnc :4" to EX_TARGET_QEMU_OPTS to start a VNC capable session...

Note: Please make sure that you have more memory than the disk size of
      ISO when you do the installs, for example, if the ISO is 1G, then
      more than 1G memory is required, usually, 2G is preferred.

## About Grub
The current installer only supports grub 2.

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

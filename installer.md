# Target Installer

Two main use cases, each of them requires two builds, one is for the
target build, the other one is for the installer itself.

1) Installer image which contains ext2, ext3 or ext4 image from target
   build to be copied to local disk.

2) Installer image which contains RPMs from target build to be installed
   to local disk.

Note: The build and installer board configuration should be the same.

## Use Case 1: Target installer with image

Create the target build image that will be installed onto the target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=intel-x86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std+installer-support \
    --enable-bootimage=ext3
    make all


Create the installer image and point to ext3 image:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=intel-x86-64 \
    --enable-kernel=standard --enable-rootfs=wr-installer \
    --enable-target-installer=yes \
    --enable-bootimage=iso \
    --with-installer-target-build=<dir1>/export/intel-x86-64-glibc-std-standard-dist.ext3
    make all

## Use case 2: Target installer with RPMs

For use case #2, create the target build project that will be installed
onto the target.

    cd dir1
    ../wrlinux-x/wrlinux/configure --enable-board=intel-x86-64 \
    --enable-kernel=standard --enable-rootfs=glibc-std+installer-support \
    make all

Create the installer image and point to top level of build:

    cd dir2
    ../wrlinux-x/wrlinux/configure --enable-board=intel-x86-64 \
    --enable-kernel=standard --enable-rootfs=wr-installer \
    --enable-target-installer=yes \
    --enable-bootimage=iso \
    --with-installer-target-build=<dir1>
    make all

## Testing

Create the qemu disk:

    host-cross/usr/bin/qemu-img create -f qcow hd0.vdisk 5000M

Start qemu with installer image:

    make start-target \
    TOPTS="-m 2048 -cd export/intel-x86-64-installer-standard-dist.iso \
    -no-kernel -disk hd0.vdisk -gc" EX_TARGET_QEMU_OPTS="-vga vmware"

Add "-vnc :4" to EX_TARGET_QEMU_OPTS to start a VNC capable session...

## About Grub
The current installer only supports grub 2.

## Adding custom installer.conf to installer image

The second build can read answers from installer.conf to help speed up the
build process when package based installs, the user can set WRL_INSTALLER_CONF
in the conf file, e.g.:

    edit <installer_build_dir>/bitbake_build/conf/local.conf
    WRL_INSTALLER_CONF = "/my/installer.conf"

You can custom the installer.conf when needed, for example, add packages that
you will like to install, but please make sure that the added packages are in the
first build.

## Do the kickstart installation
   The installer can support the kickstart installs, you can use the ks file
   from /root/anaconda-ks.cfg after the installation and edit it for later
   installs, you can specify the ks file by setting KICKSTART_FILE in the conf
   file, e.g.:

   KICKSTART_FILE = "/my/anaconda-ks.cfg"

   Then the second build will take it and start the kickstart installs
   by default when you start the target with installer image.

## Upgrade an existed OS rather than fresh install
   Note: Only the installer which contains the RPMs can do the upgrade, you
         can't use the installer which contains the image to upgrade an
         existed OS.

   Note: The previous build and current build master use the same PRSever,
         otherwise you can't do the upgrade, which means that the previous
         project_1 and the current project_1 must use the same PRSever, please
         refer to the manual on how to setup the PRSever.

   Boot the target machine with the new ISO, select "Upgrade Existing Installation"
   rather than "Fresh Installation", then the existed OS will be upgraded.

## Put multiple target builds into one installer image
   1) Create and build multiple target build projects, suppose the
      projects are named as target_build1, target_build2 and target_build3.

   2) Use the configure option --with-installer-target-build to point to
       "<target_build1>,<target_build2>,<target_build3>", the comma(,)
       is the separator:
       $ configure --enable-board=intel-x86-64 \
            --enable-kernel=standard --enable-rootfs=wr-installer \
            --enable-target-installer=yes \
            --enable-bootimage=iso \
            --with-installer-target-build=<target_build1>,<target_build2>,<target_build3>

        $ make all

        Then the installer image will contain target_build1,
        target_build2 and target_build3, you will get a selection menu when
        booting the installer image: (target_buildX is the basename of project)

        =============== Found the following products ===============
        1) DISTRO1    target_build1    DISTRO_NAME1    DISTRO_VERION1
        2) DISTRO2    target_build2    DISTRO_NAME2    DISTRO_VERION2
        3) DISTRO3    target_build3    DISTRO_NAME3    DISTRO_VERION3

        Please enter your choice (0 to quit):

        NOTE: You need to use a proper name for the target build project
              since its basename will be used in the selection menus.

        NOTE: The number of the entries in WRL_INSTALLER_CONF or
              KICKSTART_FILE must be the same as the number of target build
              projects.
              For example, if you want to use WRL_INSTALLER_CONF or
              KICKSTART_FILE for target_build1, target_build2 and
              target_build3, set each of the three in the conf file.

              WRL_INSTALLER_CONF = "/my/target1.conf /my/target2.conf \
                                     /my/target3.conf"
              KICKSTART_FILE = "/my/target1.ks /my/target2.ks \
                                /my/target3.ks"

              Then target_build1 will use /my/target1.conf and /my/target1.ks,
              target_build2 and target_build3 will work similarly.

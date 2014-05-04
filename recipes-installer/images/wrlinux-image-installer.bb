#
# Copyright (C) 2012 Wind River Systems, Inc.
#
DESCRIPTION = "An image with Anaconda support."

LICENSE = "MIT"

PR = "r0"

inherit wrlinux-image

INITRD_IMAGE = "wrlinux-image-installer-initramfs"

# We override what gets set in core-image.bbclass
IMAGE_INSTALL = "\
    packagegroup-wr-boot \
    packagegroup-core-ssh-openssh \
    ${@['', 'packagegroup-installer-x11-anaconda'][bool(d.getVar('XSERVER', True))]} \
    anaconda \
    anaconda-init \
    kernel-modules \
    windriver-gnome-theme \
    windriver-logos \
    "
IMAGE_LINGUAS = "en-us"

ROOTFS_POSTPROCESS_COMMAND += "installer_image_pp ; "

installer_image_pp () {
    bbnote "INSTALLER - modifying default runlevel"
    sed -i -e "s/^id:.:/id:5:/" ${IMAGE_ROOTFS}/etc/inittab

    # Turn off the console getty as it conflicts with the text installer
    bbnote "INSTALLER - Turn off console mingetty"
    sed -i -e "s~^S:12345:respawn:/sbin/mingetty console~#S:12345:respawn:/sbin/mingetty console~" ${IMAGE_ROOTFS}/etc/inittab

    if [ -e ${IMAGE_ROOTFS}/etc/network/interfaces ] ; then
        bbnote "INSTALLER - forcing /etc/network/interfaces"
        echo "auto lo" > ${IMAGE_ROOTFS}/etc/network/interfaces
        echo "iface lo inet loopback" >> ${IMAGE_ROOTFS}/etc/network/interfaces
    fi

    if [ -e ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules ] ; then
        bbnote "INSTALLER - turning off block device mounts"
        sed -i -e 's/^SUBSYSTEM=="block", ACTION==/#SUBSYSTEM=="block", ACTION==/' ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules
    fi

    bbnote "INSTALLER - disable lvm auto activate"
    rm -rf ${IMAGE_ROOTFS}/etc/rcS.d/*lvm2.sh
}

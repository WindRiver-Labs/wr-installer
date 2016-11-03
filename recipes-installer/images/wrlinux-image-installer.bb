#
# Copyright (C) 2012 Wind River Systems, Inc.
#
DESCRIPTION = "An image with Anaconda support."

LICENSE = "MIT"


inherit wrlinux-image

# Support installation from initrd boot
do_image_complete[depends] += "wrlinux-image-installer-initramfs:do_image_complete"

DEPENDS += "isomd5sum-native \
"

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
    dhcp-client \
    ldd \
    "
IMAGE_LINGUAS = "en-us en-gb"

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('DISTRO_FEATURES','systemd', '', 'installer_image_pp;',d)} "

installer_image_pp () {
    if [ -e ${IMAGE_ROOTFS}/etc/inittab ]; then
        bbnote "INSTALLER - modifying default runlevel"
        sed -i -e "s/^id:.:/id:5:/" ${IMAGE_ROOTFS}/etc/inittab

        # Turn off the console getty as it conflicts with the text installer
        bbnote "INSTALLER - Turn off console mingetty"
        sed -i -e "s~^S:12345:respawn:/sbin/mingetty console~#S:12345:respawn:/sbin/mingetty console~" ${IMAGE_ROOTFS}/etc/inittab
    fi

    if [ -e ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules ] ; then
        bbnote "INSTALLER - turning off block device mounts"
        sed -i -e 's/^SUBSYSTEM=="block", ACTION==/#SUBSYSTEM=="block", ACTION==/' ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules
    fi

    bbnote "INSTALLER - disable lvm auto activate"
    rm -rf ${IMAGE_ROOTFS}/etc/rcS.d/*lvm2.sh
}

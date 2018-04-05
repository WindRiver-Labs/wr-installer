DESCRIPTION = "The initramfs contains anaconda installer, which supports \
PXE (net boot installation)"

IMAGE_INSTALL = "\
    initramfs-live-boot \
    initramfs-live-install \
    initramfs-live-install-efi \
    busybox udev ldd \
    initscripts \
    ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'sysvinit', '', d)} \
    sysvinit-inittab \
    base-passwd \
    wr-init \
    kernel-modules \
    windriver-gnome-theme \
    windriver-logos \
    anaconda \
    anaconda-init \
    ${@['', 'packagegroup-installer-x11-anaconda'][bool(d.getVar('XSERVER', True))]} \
    packagegroup-wr-boot \
    packagegroup-core-ssh-openssh \
"

export IMAGE_BASENAME = "wrlinux-image-installer-initramfs"
IMAGE_LINGUAS = "en-us en-gb"

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit wrlinux-image wr-installer-rootfs

IMAGE_ROOTFS_SIZE = "8192"
INITRAMFS_MAXSIZE ?= "1100000"

ROOTFS_POSTPROCESS_COMMAND += "installer_initramfs_image_pp ; "

installer_initramfs_image_pp () {
    bbnote "INSTALLER - modifying default runlevel"
    sed -i -e "s/^id:.:/id:5:/" ${IMAGE_ROOTFS}/etc/inittab

    # Turn off the console getty as it conflicts with the text installer
    bbnote "INSTALLER - Turn off console mingetty"
    sed -i -e "s~^S:12345:respawn:/sbin/mingetty console~#S:12345:respawn:/sbin/mingetty console~" ${IMAGE_ROOTFS}/etc/inittab

    bbnote "INSTALLER - restoring root passwd"
    sed 's%^root:[^:]*:%root:x:%' < ${IMAGE_ROOTFS}/etc/passwd >${IMAGE_ROOTFS}/etc/passwd.new
    mv ${IMAGE_ROOTFS}/etc/passwd.new ${IMAGE_ROOTFS}/etc/passwd

    bbnote "INSTALLER - disable lvm auto activate"
    rm -rf ${IMAGE_ROOTFS}/etc/rcS.d/*lvm2.sh

    if [ -e ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules ] ; then
        bbnote "INSTALLER - turning off block device mounts"
        sed -i -e 's/^SUBSYSTEM=="block", ACTION==/#SUBSYSTEM=="block", ACTION==/' ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules
    fi
}

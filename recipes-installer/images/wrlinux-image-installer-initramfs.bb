# Simple initramfs image. Mostly used for live images.
DESCRIPTION = "Small image capable of booting a device. The kernel includes \
the Minimal RAM-based Initial Root Filesystem (initramfs), which finds the \
first 'init' program more efficiently."

IMAGE_INSTALL = "\
    initramfs-live-boot \
    initramfs-live-install \
    initramfs-live-install-efi \
    busybox udev \
    initscripts \
    sysvinit sysvinit-inittab \
    base-passwd \
    device-mapper \
    wr-init \
    kernel-modules \
"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

export IMAGE_BASENAME = "wrlinux-image-installer-initramfs"
IMAGE_LINGUAS = "en-us"

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit wrlinux-image

IMAGE_ROOTFS_SIZE = "8192"

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

    if [ -e ${IMAGE_ROOTFS}/etc/network/interfaces ] ; then
        bbnote "INSTALLER - forcing /etc/network/interfaces"
        echo "auto lo" > ${IMAGE_ROOTFS}/etc/network/interfaces
        echo "iface lo inet loopback" >> ${IMAGE_ROOTFS}/etc/network/interfaces
    fi

    if [ -e ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules ] ; then
        bbnote "INSTALLER - turning off block device mounts"
        sed -i -e 's/^SUBSYSTEM=="block", ACTION==/#SUBSYSTEM=="block", ACTION==/' ${IMAGE_ROOTFS}/etc/udev/rules.d/local.rules
    fi

    # Temporary workaround for WIND00386811
    touch ${IMAGE_ROOTFS}/etc/ld.so.conf

    # Generate .buildstamp
    if [ ! -f $BUILDSTAMP_FILE ]; then
        BUILDSTAMP_FILE="${IMAGE_ROOTFS}/.buildstamp"
        echo '[Main]' > $BUILDSTAMP_FILE
        echo 'Product=${DISTRO_NAME}' >> $BUILDSTAMP_FILE
        echo 'Version=${DISTRO_VERSION}' >> $BUILDSTAMP_FILE
        echo 'BugURL=http://www.windriver.com/' >> $BUILDSTAMP_FILE
        echo 'IsFinal=True' >> $BUILDSTAMP_FILE
        DATESTAMP=`date +%Y%m%d%H%M%S`
        echo "UUID=$DATESTAMP.${TARGET_ARCH}" >> $BUILDSTAMP_FILE
    fi
}

DESCRIPTION = "Packages required by target build to help the installation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

RDEPENDS_${PN} = " \
    sudo \
    kernel-image \
    grubby \
    shadow \
    efibootmgr \
    kmod \
    lvm2 \
    util-linux-mount \
    init-ifupdown \
    libuser \
    dracut \
    cryptsetup \
    sed \
    grep \
    dosfstools \
    e2fsprogs \
    btrfs-tools \
"


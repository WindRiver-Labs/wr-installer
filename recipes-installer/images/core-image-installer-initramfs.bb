DESCRIPTION = "The initramfs contains anaconda installer, which supports \
PXE (net boot installation)"

CUSTOMIZE_LOGOS ??= "place-holder-logos"

IMAGE_INSTALL = "\
    initramfs-live-boot \
    initramfs-live-install \
    initramfs-live-install-efi \
    busybox udev ldd \
    initscripts \
    ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'sysvinit', '', d)} \
    sysvinit-inittab \
    base-passwd \
    kernel-modules \
    ${CUSTOMIZE_LOGOS} \
    anaconda \
    anaconda-init \
    ${@['', 'packagegroup-installer-x11-anaconda'][bool(d.getVar('XSERVER', True))]} \
    packagegroup-core-boot \
    packagegroup-core-ssh-openssh \
"

IMAGE_LINGUAS = "en-us en-gb"

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image installer_image

IMAGE_ROOTFS_SIZE = "8192"
INITRAMFS_MAXSIZE ?= "1048576"


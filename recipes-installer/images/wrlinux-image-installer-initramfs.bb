#
# Copyright (C) 2017 Wind River Systems, Inc.
#
require recipes-installer/images/core-image-installer-initramfs.bb

python __anonymous () {
    if d.getVar('DISTRO',True) != 'wrlinux-installer':
        raise bb.parse.SkipPackage('The Wind River installer image requires DISTRO = "wrlinux-installer"')
}

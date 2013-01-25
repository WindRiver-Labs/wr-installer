#
# Copyright (C) 2012 Wind River Systems, Inc.
#
# Image generation functions to setup the installer components
#

ROOTFS_POSTPROCESS_COMMAND += "wrl_config_udev ; "

wrl_config_udev() {
    ## Turn off udev automount of local disk. This really needs to
    ## be fixed so that drives are umounted before pivot to installer rootfs
    echo "/dev/hda" >> "${IMAGE_ROOTFS}/etc/udev/mount.blacklist"
}

#Only add packages to rootfs and not initramfs
IMAGE_INSTALL += " ${@['wr-installer oe-core-installer installsw','']['init' in '${BPN}']}"

IMAGE_ROOTFS_EXTRA_SPACE += " + 204800"

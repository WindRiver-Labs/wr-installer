# Add installer specific components

inherit wr-installer-rootfs
IMAGE_INSTALL_append = " wr-installer oe-core-installer installsw"

IMAGE_ROOTFS_EXTRA_SPACE_append = " + 204800"

FILESEXTRAPATHS_append_wrlinux-installer := ":${THISDIR}/nfs-utils"

SRC_URI_append_wrlinux-installer = " file://fix-nfs-mount-without-specific-version-failed.patch \
"

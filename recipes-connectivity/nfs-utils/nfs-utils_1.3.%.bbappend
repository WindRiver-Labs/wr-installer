FILESEXTRAPATHS_append := ":${THISDIR}/nfs-utils"

SRC_URI += "file://fix-nfs-mount-without-specific-version-failed.patch \
"

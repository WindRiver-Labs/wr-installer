FILESEXTRAPATHS_append_wrlinux-installer := ":${THISDIR}/files"

SRC_URI_append_wrlinux-installer = " \
    file://init-live.sh \
"

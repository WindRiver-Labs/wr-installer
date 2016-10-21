FILESEXTRAPATHS_prepend_wrlinux-installer := "${THISDIR}/files:"
SRC_URI_append_wrlinux-installer = " file://workaround-for-anaconda-installer-while-loading-libA.patch \
"

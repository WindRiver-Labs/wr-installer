FILESEXTRAPATHS_prepend_installer := "${THISDIR}/files:"
SRC_URI_append_installer = " file://workaround-for-anaconda-installer-while-loading-libA.patch \
"

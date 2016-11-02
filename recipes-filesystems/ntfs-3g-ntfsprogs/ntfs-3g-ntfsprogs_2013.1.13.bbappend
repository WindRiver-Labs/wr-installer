FILESEXTRAPATHS_prepend_wrlinux-installer := "${THISDIR}/files:"

SRC_URI_append_wrlinux-installer = " file://fix_install_so_libs.patch"

do_install_prepend_wrlinux-installer() {
	mkdir -p ${D}${base_sbindir}
}

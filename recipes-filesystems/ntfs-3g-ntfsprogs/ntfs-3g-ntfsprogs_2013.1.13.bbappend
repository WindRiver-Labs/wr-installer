FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://fix_install_so_libs.patch"

do_install_prepend() {
	mkdir -p ${D}${base_sbindir}
}

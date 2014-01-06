do_configure_append() {
	# Hack the .pc
	sed -i 's#^pyexecdir=[^/]*#pyexecdir=${libdir}#' pygtk-2.0.pc
	sed -i 's#^datadir=.*#datadir=${STAGING_DATADIR}#' pygtk-2.0.pc
}

# Workaround for the original recipe removing pkgconfig in a do_install_append!
autotools_do_install_append() {
	mv ${D}${libdir}/pkgconfig ${D}/.
}

do_install_append() {
	mv ${D}/pkgconfig ${D}${libdir}/.
}

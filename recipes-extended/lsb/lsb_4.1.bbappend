do_install_append() {
       install -d ${D}${nonarch_base_libdir}
       mv ${D}/${baselib}/lsb ${D}${nonarch_base_libdir}
}

FILES_${PN} += "${nonarch_base_libdir}/lsb/*"

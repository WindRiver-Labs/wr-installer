do_install_append() {
    if [ ! -d ${nonarch_base_libdir}/lsb ]; then
        install -d ${D}${nonarch_base_libdir}
        mv ${D}/${baselib}/lsb ${D}${nonarch_base_libdir}
    fi
}

FILES_${PN} += "${nonarch_base_libdir}/lsb/*"

do_install_append_installer () {
    install -d ${D}${sysconfdir}/multipath
    install -m 0644 ${WORKDIR}/multipath.conf.example \
    ${D}${sysconfdir}/multipath.conf
}


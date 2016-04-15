FILESEXTRAPATHS_append := "${THISDIR}/files:"
SRC_URI += "file://0001-Update-multipath-mpathconf-from-RHEL7.patch \
           "

do_install_append () {

    install -d ${D}${sysconfdir}/multipath
    install -m 0644 ${WORKDIR}/multipath.conf.example \
    ${D}${sysconfdir}/multipath.conf
}


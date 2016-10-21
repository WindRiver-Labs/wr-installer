FILESEXTRAPATHS_append_wrlinux-installer := ":${THISDIR}/files"
SRC_URI_append_wrlinux-installer = " file://0001-Update-multipath-mpathconf-from-RHEL7.patch \
           "

do_install_append_wrlinux-installer () {

    install -d ${D}${sysconfdir}/multipath
    install -m 0644 ${WORKDIR}/multipath.conf.example \
    ${D}${sysconfdir}/multipath.conf
}


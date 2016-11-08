FILESEXTRAPATHS_prepend_wrlinux-installer := "${THISDIR}/v86d:"

SRC_URI_append_wrlinux-installer = " \
    file://uvesafb-opt.conf \
    file://fbsetup \
"

do_install_append_wrlinux-installer() {
    # Install systemd related configuration file
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${sysconfdir}/modprobe.d
        install -m 0644 ${WORKDIR}/uvesafb-opt.conf ${D}${sysconfdir}/modprobe.d
    fi
}

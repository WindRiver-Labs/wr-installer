#DEPENDS += "polkit"

inherit update-rc.d

INITSCRIPT_NAME = "NetworkManager"
INITSCRIPT_PARAMS = "defaults 20"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://NetworkManager.conf \
	file://NetworkManager.init \
	"

#EXTRA_OECONF += " \
#    --enable-polkit \
#"

do_install_prepend() {
	sed -i -e s:log_daemon_msg:log_begin_msg:g ${S}/initscript/Debian/NetworkManager
}

do_install_append() {
	install -d ${D}${sysconfdir}/NetworkManager/
	install -m 0755 ${WORKDIR}/NetworkManager.conf ${D}/${sysconfdir}/NetworkManager

	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/NetworkManager.init ${D}${sysconfdir}/init.d/${INITSCRIPT_NAME}
}

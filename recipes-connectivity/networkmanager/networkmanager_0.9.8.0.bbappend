inherit update-rc.d pkgconfig

INITSCRIPT_NAME = "NetworkManager"
INITSCRIPT_PARAMS = "defaults 20"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://NetworkManager.conf \
	file://NetworkManager.init \
	file://fix-for-libgcrypt-config.patch \
	"

# We don't need polkit in wr-installer and drop the recipes,
# so disable it explicitly.
EXTRA_OECONF += " \
    --disable-polkit \
"
# And override the config for systemd to remove polkit option
# (it is enable in meta-oe).
PACKAGECONFIG[systemd] = " \
    --with-systemdsystemunitdir=${systemd_unitdir}/system --with-session-tracking=systemd, \
    --with-systemdsystemunitdir=no,, \
"

do_install_prepend() {
	sed -i -e s:log_daemon_msg:log_begin_msg:g ${B}/initscript/Debian/NetworkManager
}

do_install_append() {
	install -d ${D}${sysconfdir}/NetworkManager/
	install -m 0755 ${WORKDIR}/NetworkManager.conf ${D}/${sysconfdir}/NetworkManager

	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/NetworkManager.init ${D}${sysconfdir}/init.d/${INITSCRIPT_NAME}
}

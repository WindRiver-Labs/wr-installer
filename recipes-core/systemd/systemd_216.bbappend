#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# LOCAL REV: 1) add WR-installer specific dhclient config file;
#            2) recreate symlink gettty@tty1.service to anaconda-init-
#               tmux@.service which display text mode anaconda installer
#               on tty1 by default.
#
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://wr-dhcp.network \
	"

PACKAGECONFIG = "xz networkd"

do_install_append() {
	install -m 0755 ${WORKDIR}/wr-dhcp.network ${D}${sysconfdir}/systemd/network

	ln -nsf ${systemd_unitdir}/system/anaconda-init-tmux@.service \
		${D}${sysconfdir}/systemd/system/getty.target.wants/getty@tty1.service
}

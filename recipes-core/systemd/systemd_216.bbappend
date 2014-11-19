#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# LOCAL REV: add WR-installer specific dhclient config file
#
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://wr-dhcp.network \
	"

PACKAGECONFIG = "xz networkd"

do_install_append() {
	install -m 0755 ${WORKDIR}/wr-dhcp.network ${D}${sysconfdir}/systemd/network
}

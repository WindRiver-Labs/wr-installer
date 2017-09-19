#
# Copyright (C) 2012-2014 Wind River Systems, Inc.
#
# LOCAL REV: 1) add WR-installer specific dhclient config file;
#            2) recreate symlink gettty@tty1.service to anaconda-init-
#               screen@.service which display text mode anaconda installer
#               on tty1 by default.
#
FILESEXTRAPATHS_prepend_installer := "${THISDIR}/files:"

do_install_append_installer() {
	ln -nsf ${systemd_unitdir}/system/anaconda-init-screen@.service \
		${D}${sysconfdir}/systemd/system/getty.target.wants/getty@tty1.service
}

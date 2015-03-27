#
# Copyright (C) 2012-2015 Wind River Systems, Inc.
#            1) recreate symlink serial-getty to anaconda-init-tmux@.service
#               which display text mode anaconda installer on serial console
#               by default.
#
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_install_append() {
    if [ ! -z "${SERIAL_CONSOLES}" ] ; then
        default_baudrate=`echo "${SERIAL_CONSOLES}" | sed 's/\;.*//'`

        tmp="${SERIAL_CONSOLES}"
        for entry in $tmp ; do
            baudrate=`echo $entry | sed 's/\;.*//'`
            ttydev=`echo $entry | sed -e 's/^[0-9]*\;//' -e 's/\;.*//'`
            if [ "$baudrate" = "$default_baudrate" ] ; then
                # enable the service
                ln -snf ${systemd_unitdir}/system/anaconda-init-tmux@.service \
                    ${D}${sysconfdir}/systemd/system/getty.target.wants/serial-getty@$ttydev.service
            else
                # install custom service file for the non-default baudrate
                # enable the service
                ln -sfn ${systemd_unitdir}/system/anaconda-init-tmux@.service \
                    ${D}${sysconfdir}/systemd/system/getty.target.wants/serial-getty$baudrate@$ttydev.service
            fi
        done
    fi
}


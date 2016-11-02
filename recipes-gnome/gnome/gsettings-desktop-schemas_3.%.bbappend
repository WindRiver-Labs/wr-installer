gsettings_postinstrm_wrlinux-installer () {
    glib-compile-schemas $D${datadir}/glib-2.0/schemas &> /dev/null
}


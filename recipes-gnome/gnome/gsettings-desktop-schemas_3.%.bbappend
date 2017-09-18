gsettings_postinstrm_installer () {
    glib-compile-schemas $D${datadir}/glib-2.0/schemas &> /dev/null
}


gsettings_postinstrm () {
    glib-compile-schemas $D${datadir}/glib-2.0/schemas &> /dev/null
}


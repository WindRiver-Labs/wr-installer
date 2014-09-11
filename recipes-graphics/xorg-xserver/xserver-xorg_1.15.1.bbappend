# RRECOMMENDS_${PN} = "${PN}-security-policy xkeyboard-config rgb"

PACKAGES += "${PN}-source"

XSERVER_SOURCE_DIR="${datadir}/${PN}-source"
FILES_${PN}-source = "${XSERVER_SOURCE_DIR}"

do_install_append () {
    for subdir in Xext xkb GL hw/xquartz/bundle hw/xfree86/common; do
        install -d ${D}${XSERVER_SOURCE_DIR}/$subdir
    done
    for subdir in hw/dmx/doc man doc hw/dmx/doxygen; do
        install -d ${D}${XSERVER_SOURCE_DIR}/$subdir
    done

    sources="hw/xquartz/bundle/cpprules.in man/Xserver.man doc/smartsched \
             hw/dmx/doxygen/doxygen.conf.in xserver.ent.in xkb/README.compiled \
             hw/xfree86/xorgconf.cpp"
    for i in ${sources}; do \
    install -m 0644 ${S}/$i ${D}${XSERVER_SOURCE_DIR}/$i; done

    cd ${S}
    find . -type f | egrep '.*\.(c|h|am|ac|inc|m4|h.in|pc.in|man.pre|pl|txt)$' | \
    xargs tar cf - | (cd ${D}${XSERVER_SOURCE_DIR} && tar xf -)
    cd ${B}
    find . -type f | egrep '.*\.(c|h|am|ac|inc|m4|h.in|pc.in|man.pre|pl|txt)$' | \
    xargs tar cf - | (cd ${D}${XSERVER_SOURCE_DIR} && tar xf -)
    # SLEDGEHAMMER
    find ${D}${XSERVER_SOURCE_DIR}/hw/xfree86 -name \*.c -delete
}

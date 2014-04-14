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

    install -m 0644 hw/xquartz/bundle/cpprules.in ${D}${XSERVER_SOURCE_DIR}/hw/xquartz/bundle/cpprules.in
    install -m 0644 man/Xserver.man ${D}${XSERVER_SOURCE_DIR}/man/Xserver.man
    install -m 0644 doc/smartsched ${D}${XSERVER_SOURCE_DIR}/doc/smartsched
    install -m 0644 hw/dmx/doxygen/doxygen.conf.in ${D}${XSERVER_SOURCE_DIR}/hw/dmx/doxygen
    install -m 0644 xserver.ent.in ${D}${XSERVER_SOURCE_DIR}/xserver.ent.in
    install -m 0644 xkb/README.compiled ${D}${XSERVER_SOURCE_DIR}/xkb/README.compiled
    install -m 0644 hw/xfree86/xorgconf.cpp ${D}${XSERVER_SOURCE_DIR}/hw/xfree86

    find . -type f | egrep '.*\.(c|h|am|ac|inc|m4|h.in|pc.in|man.pre|pl|txt)$' | \
    xargs tar cf - | (cd ${D}${XSERVER_SOURCE_DIR} && tar xf -)
    # SLEDGEHAMMER
    find ${D}${XSERVER_SOURCE_DIR}/hw/xfree86 -name \*.c -delete
}

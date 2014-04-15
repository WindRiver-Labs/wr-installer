#
# Copyright (C) 2012 Wind River Systems, Inc.
#
SUMMARY = "iSCSI daemon and utility programs"
DESCRIPTION = \
"Open-iSCSI project is a high performance, transport independent, \
multi-platform implementation of RFC3720. The iscsi package provides \
the server daemon for the iSCSI protocol, as well as the utility \
programs used to manage it. iSCSI is a protocol for distributed \
disk access using SCSI commands sent over Internet Protocol networks."
SECTION = "console/network"

HOMEPAGE = "http://www.open-iscsi.org/"
INC_PR = "r3"

UPSTREAM_name = "open-iscsi"

#iscsi-initiator-utils-{use-var-for-config}.patch are from fedora
#change nodes,send_targets... from /etc/iscsi to /var/lib/iscsi
SRC_URI = "http://www.open-iscsi.org/bits/${UPSTREAM_name}-${PV}.tar.gz \
	   file://iscsi-initiator-utils-use-var-for-config.patch \
	   file://iscsi-initiator-utils-dont-use-static.patch	\
	   file://initd.debian	\
	   file://iscsi-initiator-utils-sync-uio-0.7.0.8.patch \
	   file://iscsi-initiator-utils-update-initscripts-and-docs.patch \
	   file://iscsi-initiator-utils-add-libiscsi.patch \
	   file://iscsi-initiator-utils-uip-mgmt.patch \
	   file://iscsi-initiator-utils-remove-the-offload-boot-supported-ifdef.patch \
	   file://iscsi-initiator-utils-uio-handle-different-iface_rec.patch \
	   file://iscsi-initiator-utils-brcm-man.patch \
	   file://iscsi-initiator-utils-sync-uio-0.7.0.14.patch \
	   file://04-iscsi \
	   file://iscsidevs.init \
	   file://iscsid.init \
"
S = "${WORKDIR}/${UPSTREAM_name}-${PV}"
TARGET_CC_ARCH += "${LDFLAGS}"

#utils/fwparam_ibft/prom_parse.y utils/fwparam_ibft/prom_lex.l
#already parsed in source 2.0 but still depends on flex and bison 
#native in case future version they are not parsed
DEPENDS += "openssl flex-native bison-native python-setuptools-native python-native python \
 doxygen-native \
"

PACKAGES =+ "${PN}-tests ${PN}-python ${PN}-python-dbg"

FILES_${PN}-tests = "/opt/${PN}-tests/*"
RDEPENDS_${PN}-tests = "perl"
RDEPENDS_${PN}-python = "python"

inherit update-rc.d python-dir

FILES_${PN}-dev = "${libdir}/libiscsi.so ${includedir}/libiscsi.h"
FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/libiscsimodule.so"
FILES_${PN}-python-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug/libiscsimodule.so"


do_configure () {
	#need to support cross-compiling in open-isns only
	(cd utils/open-isns; \
	    autoreconf -Wcross --verbose --install --force; \
	    ./configure --host=${TARGET_SYS} --build=${BUILD_SYS} --with-security=no )
	(cd iscsiuio; rm aclocal.m4; touch AUTHORS NEWS TODO; \
	    autoreconf -Wcross --verbose --install --force; \
        chmod u+x configure;
	    ./configure --host=${TARGET_SYS} --build=${BUILD_SYS} --enable-debug )
}

do_compile () {
	#make iscsistart one of PROGRAMS if install_user in do_install
	#sed -i -e '/^PROGRAMS = /s;$; usr/iscsistart;' Makefile

	#fix the ar used in open-isns
	sed -i -e 's:ar cr :$(AR) cr :' ${S}/utils/open-isns/Makefile
	oe_runmake user
        oe_runmake -C iscsiuio
        (cd libiscsi; \
         STAGING_INCDIR=${STAGING_INCDIR} \
         STAGING_LIBDIR=${STAGING_LIBDIR} \
         BUILD_SYS=${BUILD_SYS} HOST_SYS=${HOST_SYS} \
         ${STAGING_BINDIR_NATIVE}/python-native/python setup.py build ${DISTUTILS_BUILD_ARGS} || \
         bbfatal "python setup.py build_ext execution failed."; \
         touch -r libiscsi.doxy html/* )
}

do_install () {
	#completely override the install_user as bugs in Makefile
	#oe_runmake DESTDIR="${D}" install_user

	#install necessary directories
	install -d ${D}${base_sbindir} \
                ${D}${libdir} \    
                ${D}${includedir} \    
                ${D}${PYTHON_SITEPACKAGES_DIR} \
		${D}${sysconfdir}/init.d \
		${D}${sysconfdir}/iscsi \
                ${D}${sysconfdir}/logrotate.d \
                ${D}${sysconfdir}/NetworkManager/dispatcher.d \
		${D}${localstatedir}/lib/iscsi/nodes \
		${D}${localstatedir}/lib/iscsi/send_targets \
		${D}${localstatedir}/lib/iscsi/static \
		${D}${localstatedir}/lib/iscsi/isns \
		${D}${localstatedir}/lib/iscsi/slp \
		${D}${localstatedir}/lib/iscsi/ifaces \
		${D}${localstatedir}/lock/iscsi ${D}/${mandir}/man8

	install -p -m 755 ${S}/usr/iscsid ${S}/usr/iscsiadm \
		${S}/utils/iscsi-iname \
		${S}/usr/iscsistart ${D}/${base_sbindir}

	install -p -m 644 ${S}/doc/iscsiadm.8 ${S}/doc/iscsid.8 ${S}/doc/iscsistart.8 ${S}/doc/iscsi-iname.8 ${S}/iscsiuio/docs/iscsiuio.8 ${D}/${mandir}/man8
	install -p -m 644 ${S}/etc/iscsid.conf ${D}${sysconfdir}/iscsi
        install -p -m 644 ${S}/iscsiuio/iscsiuiolog ${D}${sysconfdir}/logrotate.d
        install -p -m 755 ${S}/iscsiuio/src/unix/iscsiuio ${D}${base_sbindir}
	install -p -m 755 ${WORKDIR}/iscsid.init ${D}${sysconfdir}/init.d/iscsid
	install -p -m 755 ${WORKDIR}/iscsidevs.init ${D}${sysconfdir}/init.d/iscsid
	install -p -m 755 ${WORKDIR}/04-iscsi ${D}${sysconfdir}/NetworkManager/dispatcher.d

	install -p -m 755 ${S}/libiscsi/libiscsi.so.0 ${D}/${libdir}
        ln -s libiscsi.so.0 ${D}/${libdir}/libiscsi.so
	install -p -m 644 ${S}/libiscsi/libiscsi.h ${D}/${includedir}
	install -p -m 755 ${S}/libiscsi/build/lib.linux-*/libiscsimodule.so ${D}/${PYTHON_SITEPACKAGES_DIR}

	#install regression tests
	[ ! -d ${D}/opt/${PN}-tests ] && mkdir -p ${D}/opt/${PN}-tests
	install ${S}/test/{regression.dat,regression.sh} ${D}/opt/${PN}-tests/

	#open-isns tests
	mkdir -p ${D}/opt/${PN}-tests/isns-tests
	install ${S}/utils/open-isns/tests/*.pl ${D}/opt/${PN}-tests/isns-tests/
	install ${S}/utils/open-isns/tests/genkey \
		${S}/utils/open-isns/tests/client.conf \
		${S}/utils/open-isns/tests/server.conf \
		${D}/opt/${PN}-tests/isns-tests/
	cp -a ${S}/utils/open-isns/tests/data ${D}/opt/${PN}-tests/isns-tests/
}

pkg_postinst_${PN}() {
	#default there is no initiatorname.iscsi installed
	#but it is needed or iscsid will fail
	if [ ! -f ${sysconfdir}/iscsi/initiatorname.iscsi ]; then
		echo "InitiatorName=$(${base_sbindir}/iscsi-iname)" > \
		${sysconfdir}/iscsi/initiatorname.iscsi
	fi
}

INITSCRIPT_NAME = "iscsid"
INITSCRIPT_PARAMS = "start 30 . stop 70 0 1 2 3 4 5 6 ."

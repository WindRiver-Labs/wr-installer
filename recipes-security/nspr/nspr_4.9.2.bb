#
# Copyright (C) 2012 Wind River Systems, Inc.
#
DESCRIPTION = "Netscape Portable Runtime Library"
HOMEPAGE =  "http://www.mozilla.org/projects/nspr/"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"
SECTION = "libs/network"

PR = "r0"

SRC_URI = "ftp://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v${PV}/src/${PN}-${PV}.tar.gz \ 
           file://remove-rpath-from-tests.patch \
           file://fix-build-on-x86_64.patch \
           file://trickly-fix-build-on-x86_64.patch \
          "

SRC_URI[md5sum] = "1a8cad110e0ae94f538610a00f595b33"
SRC_URI[sha256sum] = "570206f125fc31b8589b31d3837c190ee2a75d4f3b8faec2cbedbeacc016e82c"

S = "${WORKDIR}/nspr-${PV}/mozilla/nsprpub"

TESTS = "runtests.pl \
    runtests.sh \
    accept \
    acceptread \
    acceptreademu \
    affinity \
    alarm \
    anonfm \
    atomic \
    attach \
    bigfile \
    cleanup \
    cltsrv  \
    concur \
    cvar \
    cvar2 \
    dlltest \
    dtoa \
    errcodes \
    exit \
    fdcach \
    fileio \
    foreign \
    formattm \
    fsync \
    gethost \
    getproto \
    i2l \
    initclk \
    inrval \
    instrumt \
    intrio \
    intrupt \
    io_timeout \
    ioconthr \
    join \
    joinkk \
    joinku \
    joinuk \
    joinuu \
    layer \
    lazyinit \
    libfilename \
    lltest \
    lock \
    lockfile \
    logfile \
    logger \
    many_cv \
    multiwait \
    nameshm1 \
    nblayer \
    nonblock \
    ntioto \
    ntoh \
    op_2long \
    op_excl \
    op_filnf \
    op_filok \
    op_nofil \
    parent \
    parsetm \
    peek \
    perf \
    pipeping \
    pipeping2 \
    pipeself \
    poll_nm \
    poll_to \
    pollable \
    prftest \
    primblok \
    provider \
    prpollml \
    ranfile \
    randseed \
    reinit \
    rwlocktest \
    sel_spd \
    selct_er \
    selct_nm \
    selct_to \
    selintr \
    sema \
    semaerr \
    semaping \
    sendzlf \
    server_test \
    servr_kk \
    servr_uk \
    servr_ku \
    servr_uu \
    short_thread \
    sigpipe \
    socket \
    sockopt \
    sockping \
    sprintf \
    stack \
    stdio \
    str2addr \
    strod \
    switch \
    system \
    testbit \
    testfile \
    threads \
    timemac \
    timetest \
    tpd \
    udpsrv \
    vercheck \
    version \
    writev \
    xnotify \
    zerolen"

inherit autotools

EXTRA_OECONF += "\
	--target=${TARGET_SYS} --host=${TARGET_SYS} \
	--includedir=${includedir}/nspr4 \
	--libdir=${base_libdir} \
	"

do_configure() {
	oe_runconf
}

do_compile_prepend() {
	oe_runmake CROSS_COMPILE=1 CFLAGS="-DXP_UNIX" LDFLAGS="" CC=gcc -C config export
}

do_compile_append() {
	oe_runmake -C pr/tests
}

do_install_append() {
	if [ ! -e ${D}${libdir} ]; then mkdir -p ${D}${libdir}; fi
	mv ${D}/${base_libdir}/pkgconfig ${D}/${libdir}/pkgconfig

	cd ${S}/pr/tests
	mkdir -p ${D}${libdir}/nspr/tests
	install -m 0755 ${TESTS} ${D}${libdir}/nspr/tests

	rm ${D}/${bindir}/compile-et.pl ${D}/${bindir}/prerr.properties
	rm ${D}/${base_libdir}/lib*.a 
}

FILES_${PN} = "${bindir}/* ${base_libdir}/lib*.so"
FILES_${PN}-dev = "${libdir}/nspr/tests/* ${libdir}/pkgconfig/* \
      ${includedir}/* ${datadir}/aclocal/* "
FILES_${PN}-dbg += "${libdir}/nspr/tests/.debug/*"

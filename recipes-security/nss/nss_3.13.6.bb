#
# Copyright (C) 2012 Wind River Systems, Inc.
#
SUMMARY = "Mozilla's SSL and TLS implementation"
DESCRIPTION = "Network Security Services (NSS) is a set of libraries \
	designed to support cross-platform development of \
	security-enabled client and server applications. \
	Applications built with NSS can support SSL v2 and v3, \
	TLS, PKCS 5, PKCS 7, PKCS 11, PKCS 12, S/MIME, X.509 \
	v3 certificates, and other security standards."
HOMEPAGE = "http://www.mozilla.org/projects/security/pki/nss/"
SECTION = "libs"

inherit siteinfo

PR = "r2"

LICENSE = "MPL-1.1 GPL-2.0 LGPL-2.1"

LIC_FILES_CHKSUM = "file://mozilla/security/nss/lib/freebl/mpi/doc/LICENSE;md5=491f158d09d948466afce85d6f1fe18f \
                    file://mozilla/security/nss/lib/freebl/mpi/doc/LICENSE-MPL;md5=6bf96825e3d7ce4de25621ae886cc859"

DEPENDS = "sqlite3 nspr zlib"

RDEPENDS_${PN} = "perl"

SRC_URI = "\
	http://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/NSS_3_13_6_RTM/src/${PN}-${PV}.tar.gz;name=archive \
	file://nss-no-rpath.patch;striplevel=0 \
	file://nss-fixrandom.patch;striplevel=0 \
	file://nss-3.12.7-format_not_a_string_literal_and_no_format_arguments.patch \
	file://renegotiate-transitional.patch;striplevel=0 \
	file://wr-cross-compile-support.patch \
	file://fix_config.patch \
	file://nss.pc.in \
	file://nss-config.in \
	file://blank-cert8.db \
	file://blank-key3.db \
	file://blank-secmod.db \
	file://certdata_empty.txt \
	file://signlibs.sh \
"

SRC_URI[archive.md5sum] = "15ea0e3b63cd0d18b5b75619afc46c3e"
SRC_URI[archive.sha256sum] = "f7e90727e0ecc1c29de10da39a79bc9c53b814ccfbf40720e053b29c683d43a0"

TD = "${S}/tentative-dist"
TDS = "${S}/tentative-dist-staging"

PARALLEL_MAKE = ""

TARGET_CC_ARCH += "${LDFLAGS}"

do_compile() {
	mkdir -p host
	cd host
	mkdir -p mozilla/security
	cp -a ../mozilla/security/coreconf mozilla/security/.
	make -C ./mozilla/security/coreconf/nsinstall OS_TEST=x86 OS_RELEASE=3.4 OS_ARCH=Linux OS_TARGET=Linux COMPILER_TAG="" AR="ar" RANLIB="ranlib" NATIVE_CC="gcc" NATIVE_FLAGS="-g -O2 -fomit-frame-pointer -fPIC -pipe "
	cd ..

	export FREEBL_NO_DEPEND=1
	export BUILD_OPT=1

	export LIBDIR=${base_libdir}
	export USE_SYSTEM_ZLIB=1
	export ZLIB_LIBS="-lz"
	export NSPR_INCLUDE_DIR=${STAGING_INCDIR}/nspr4
	export NSPR_LIB_DIR=${STAGING_DIR_TARGET}/${base_libdir}
	export MOZILLA_CLIENT=1
	export NS_USE_GCC=1
	export NSS_USE_SYSTEM_SQLITE=1
	export NSS_ENABLE_ECC=1

	export NSINSTALL=`pwd`/host/mozilla/security/coreconf/nsinstall/Linux3.4_x86_glibc_PTH_DBG.OBJ/nsinstall
	export OS_RELEASE=3.4
	export OS_TARGET=Linux
	export OS_ARCH=Linux

	if [ "${TARGET_ARCH}" = "powerpc" ]; then
		OS_TEST=ppc
	elif [ "${TARGET_ARCH}" = "powerpc64" ]; then
		OS_TEST=ppc64
	elif [ "${TARGET_ARCH}" = "mips" -o "${TARGET_ARCH}" = "mipsel" -o "${TARGET_ARCH}" = "mips64" -o "${TARGET_ARCH}" = "mips64el" ]; then
		OS_TEST=mips
	else
		OS_TEST="${TARGET_ARCH}"
	fi
	if [ "${SITEINFO_BITS}" = "64" ]; then
		export USE_64=1
	fi

	make -C ./mozilla/security/nss \
	  OS_TEST=${OS_TEST} OS_RELEASE=${OS_RELEASE} OS_ARCH=${OS_ARCH} \
	  OS_TARGET=${OS_TARGET} NSINSTALL=${NSINSTALL} RANLIB=${RANLIB} \
	  DEFAULT_COMPILER="${CC}" \
	  CC="${CC}" \
	  CCC="${CXX}" \
	  CXX="${CXX}" \
	  RANLIB="${RANLIB}" \
	  build_coreconf build_dbm all
}

do_install() {
	export FREEBL_NO_DEPEND=1
	export BUILD_OPT=1

	export LIBDIR=${base_libdir}
	export USE_SYSTEM_ZLIB=1
	export ZLIB_LIBS="-lz"
	export NSPR_INCLUDE_DIR=${STAGING_INCDIR}/nspr4
	export NSPR_LIB_DIR=${STAGING_DIR_TARGET}/${base_libdir}
	export MOZILLA_CLIENT=1
	export NS_USE_GCC=1
	export NSS_USE_SYSTEM_SQLITE=1
	export NSS_ENABLE_ECC=1

	export NSINSTALL=`pwd`/host/mozilla/security/coreconf/nsinstall/Linux3.4_x86_glibc_PTH_DBG.OBJ/nsinstall
	export OS_RELEASE=3.4
	export OS_TARGET=Linux
	export OS_ARCH=Linux

	if [ "${TARGET_ARCH}" = "powerpc" ]; then
		OS_TEST=ppc
	elif [ "${TARGET_ARCH}" = "powerpc64" ]; then
		OS_TEST=ppc64
	elif [ "${TARGET_ARCH}" = "mips" -o "${TARGET_ARCH}" = "mipsel" -o "${TARGET_ARCH}" = "mips64" -o "${TARGET_ARCH}" = "mips64el" ]; then
		OS_TEST=mips
	else
		OS_TEST="${TARGET_ARCH}"
	fi
	if [ "${SITEINFO_BITS}" = "64" ]; then
		export USE_64=1
	fi

	make -C ./mozilla/security/nss \
	  OS_TEST=${OS_TEST} OS_RELEASE=${OS_RELEASE} OS_ARCH=${OS_ARCH} \
	  OS_TARGET=${OS_TARGET} NSINSTALL=${NSINSTALL} RANLIB=${RANLIB} \
	  DEFAULT_COMPILER="${CC}" \
	  CC="${CC}" \
	  CCC="${CXX}" \
	  CXX="${CXX}" \
	  RANLIB="${RANLIB}" \
	  SOURCE_LIB_DIR="${TD}/${libdir}" 	\
	  SOURCE_BIN_DIR="${TD}/${bindir}" \
	  install

	install -d ${D}/${base_libdir}/nss

	for file in ${S}/mozilla/dist/*.OBJ/lib/*.so; do
		echo "Installing `basename $file`..."
		cp $file  ${D}/${base_libdir}/
	done
	for file in libsoftokn3.chk libfreebl3.chk libnssdbm3.chk; do
		touch ${D}/${base_libdir}/$file
		chmod 755 ${D}/${base_libdir}/$file
	done
	install -D -m 755 ${WORKDIR}/signlibs.sh ${D}/${bindir}/signlibs.sh

	for shared_lib in "${TD}/${libdir}/*.so.*"
	do
		if [ -f $shared_lib ]; then
			cp $shared_lib ${D}/${base_libdir}
			ln -sf $(basename $shared_lib) ${D}/${base_libdir}/$(basename $shared_lib .1oe)
		fi
	done
	for shared_lib in ${TD}/${libdir}/*.so
	do
		if [ -f $shared_lib -a ! -e ${D}/${base_libdir}/$shared_lib ]; then
			cp $shared_lib ${D}/${base_libdir}
		fi
	done

	install -d ${D}/${includedir}/nss3
	install -m 644 -t ${D}/${includedir}/nss3 mozilla/dist/public/nss/*

	install -d ${D}/${bindir}
	for binary in ${TD}/${bindir}/*
	do
		install -m 755 -t ${D}/${bindir} $binary
	done

	install -d ${D}${libdir}/pkgconfig/
	sed 's/%NSS_VERSION%/${PV}/' ${WORKDIR}/nss.pc.in | sed 's/%NSPR_VERSION%/4.9.2/' > ${D}${libdir}/pkgconfig/nss.pc
	sed -i s:OEPREFIX:${prefix}:g ${D}${libdir}/pkgconfig/nss.pc
	sed -i s:OEEXECPREFIX:${exec_prefix}:g ${D}${libdir}/pkgconfig/nss.pc
	sed -i s:OELIBDIR:${base_libdir}:g ${D}${libdir}/pkgconfig/nss.pc
	sed -i s:OEINCDIR:${includedir}/nss3:g ${D}${libdir}/pkgconfig/nss.pc

	mkdir -p ${D}/etc/pki/nssdb/
	install -m 644 ${WORKDIR}/blank-cert8.db ${D}/etc/pki/nssdb/cert8.db
	install -m 644 ${WORKDIR}/blank-key3.db ${D}/etc/pki/nssdb/key3.db
	install -m 644 ${WORKDIR}/blank-secmod.db ${D}/etc/pki/nssdb/secmod.db
}

FILES_${PN} = "\
		${sysconfdir} \
		${bindir} \
		${base_libdir}/lib*.chk \
		${base_libdir}/lib*.so \
		"

FILES_${PN}-dev = "\
		${base_libdir}/nss \
		${libdir}/pkgconfig/* \
		${includedir}/* \
		"

FILES_${PN}-dbg += "\
		${bindir}/.debug/* \
		"
